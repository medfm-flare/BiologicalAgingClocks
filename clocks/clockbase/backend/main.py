"""
ClockBase API - Main Application Module

A comprehensive platform for biological age profiling in human and mouse.
"""

import logging
import sys
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any

import pandas as pd
from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from loguru import logger
from pydantic import ValidationError
from pydantic_settings import BaseSettings, SettingsConfigDict
from starlette.exceptions import HTTPException as StarletteHTTPException

from endpoints import coords, gse, metadata, plots, interventions

# ============================================================================
# Configuration with Pydantic Settings
# ============================================================================


class Settings(BaseSettings):
    """Application settings with environment variable support."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Server settings
    app_name: str = "ClockBase API"
    app_version: str = "1.0.0"
    debug: bool = False

    # Paths
    data_dir: Path = Path("./data")
    frontend_dir: Path = Path("../frontend/dist")
    log_dir: Path = Path("./logs")

    # CORS settings
    cors_origins: list[str] = ["http://localhost:3000", "http://localhost:5173"]
    cors_allow_credentials: bool = True
    cors_allow_methods: list[str] = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    cors_allow_headers: list[str] = ["*"]

    # Logging
    log_level: str = "DEBUG"
    log_rotation: str = "00:00"
    log_retention: str = "7 days"

    def validate_paths(self) -> None:
        """Validate that required paths exist."""
        if not self.data_dir.exists():
            raise ValueError(f"Data directory not found: {self.data_dir}")

        # Create log directory if it doesn't exist
        self.log_dir.mkdir(parents=True, exist_ok=True)


# Initialize settings
try:
    settings = Settings()
    settings.validate_paths()
except ValidationError as e:
    print(f"Configuration error: {e}", file=sys.stderr)
    sys.exit(1)


# ============================================================================
# Logger Setup
# ============================================================================


class InterceptHandler(logging.Handler):
    """Intercept standard logging and redirect to loguru."""

    def emit(self, record: logging.LogRecord) -> None:
        """Emit a log record through loguru."""
        # Get corresponding Loguru level
        try:
            level = logger.level(record.levelname).name
        except ValueError:
            level = record.levelno

        # Find caller from where the logged message originated
        frame = logging.currentframe()
        depth = 2
        while frame and frame.f_code.co_filename == logging.__file__:
            frame = frame.f_back
            depth += 1

        logger.opt(depth=depth, exception=record.exc_info).log(level, record.getMessage())


def configure_logger() -> None:
    """Configure loguru with colorful, readable output."""
    # Remove default handler
    logger.remove()

    # Add colorful console handler with custom format
    logger.add(
        sink=sys.stdout,
        format=(
            "<green>{time:YYYY-MM-DD HH:mm:ss}</green> | "
            "<level>{level: <8}</level> | "
            "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> | "
            "<level>{message}</level>"
        ),
        level=settings.log_level,
        colorize=True,
    )

    # Add file handler for persistent logs
    logger.add(
        settings.log_dir / "app_{time:YYYY-MM-DD}.log",
        rotation=settings.log_rotation,
        retention=settings.log_retention,
        level=settings.log_level,
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{function}:{line} | {message}",
        enqueue=True,  # Thread-safe logging
    )

    logger.info(f"Logger configured with level: {settings.log_level}")


def setup_logging_interception() -> None:
    """Intercept uvicorn and FastAPI logs and redirect to loguru."""
    logging.basicConfig(handlers=[InterceptHandler()], level=0, force=True)

    for logger_name in ("uvicorn", "uvicorn.access", "uvicorn.error", "fastapi"):
        logging_logger = logging.getLogger(logger_name)
        logging_logger.handlers = [InterceptHandler()]
        logging_logger.propagate = False


# ============================================================================
# Data Loading with Error Handling
# ============================================================================


class DataCache:
    """Cache for application data."""

    def __init__(self):
        self.clock_table: list[dict] | None = None

    def load_clock_table(self) -> list[dict]:
        """Load and process clock table data with caching."""
        if self.clock_table is not None:
            return self.clock_table

        try:
            clock_table_path = settings.data_dir / "clock_table.csv"

            if not clock_table_path.exists():
                raise FileNotFoundError(f"Clock table not found at: {clock_table_path}")

            logger.info(f"Loading clock table from: {clock_table_path}")
            df = pd.read_csv(clock_table_path)

            # Process data
            if "# of CpGs" in df.columns:
                df["# of CpGs"] = df["# of CpGs"].str.replace(",", "").astype(int)

            self.clock_table = df.to_dict("records")
            logger.info(f"Clock table loaded successfully with {len(self.clock_table)} records")

            return self.clock_table

        except Exception as e:
            logger.error(f"Failed to load clock table: {e}")
            raise


# Initialize data cache
data_cache = DataCache()


# ============================================================================
# Custom Static Files Handler for SPA
# ============================================================================


class SPAStaticFiles(StaticFiles):
    """Custom StaticFiles handler for SPA routing (serves index.html on 404)."""

    async def get_response(self, path: str, scope):
        """Get response with SPA fallback to index.html."""
        try:
            return await super().get_response(path, scope)
        except StarletteHTTPException as ex:
            if ex.status_code == 404:
                # Don't serve index.html for API 404 errors
                request_path = scope.get("path", "")
                if request_path.startswith("/api/"):
                    raise  # Let FastAPI return proper 404 JSON response

                # For SPA routes, serve index.html
                return await super().get_response("index.html", scope)
            raise


# ============================================================================
# Exception Handlers
# ============================================================================


async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    """Handle validation errors."""
    logger.warning(f"Validation error on {request.url}: {exc.errors()}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "detail": exc.errors(),
            "body": exc.body,
        },
    )


async def generic_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Handle generic exceptions."""
    logger.error(f"Unhandled exception on {request.url}: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "detail": "Internal server error",
            "message": str(exc) if settings.debug else "An error occurred",
        },
    )


# ============================================================================
# Application Lifespan Management
# ============================================================================


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan (startup and shutdown)."""
    # Startup
    logger.info("Starting ClockBase API...")

    try:
        # Preload data
        data_cache.load_clock_table()
        logger.info("Data preloaded successfully")
    except Exception as e:
        logger.error(f"Failed to preload data: {e}")
        raise

    logger.info("Application startup complete")

    yield

    # Shutdown
    logger.info("Shutting down ClockBase API...")
    # Add any cleanup code here
    logger.info("Application shutdown complete")


# ============================================================================
# Application Factory
# ============================================================================


def create_app() -> FastAPI:
    """Create and configure FastAPI application."""
    # Configure logging first
    configure_logger()
    setup_logging_interception()

    # Create app with lifespan
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        debug=settings.debug,
        lifespan=lifespan,
    )

    # Add CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=settings.cors_allow_credentials,
        allow_methods=settings.cors_allow_methods,
        allow_headers=settings.cors_allow_headers,
    )

    # Register exception handlers
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    app.add_exception_handler(Exception, generic_exception_handler)

    # Include API routers
    api_routers = [
        (coords.router, "coordinates"),
        (metadata.router, "metadata"),
        (gse.router, "gse"),
        (plots.router, "plots"),
        (interventions.router, "interventions"),
    ]

    for router, name in api_routers:
        app.include_router(router, prefix="/api", tags=[name])
        logger.info(f"Registered router: {name}")

    # ========================================================================
    # API Endpoints
    # ========================================================================

    @app.get("/api/clock-table", tags=["data"])
    async def get_clock_table() -> list[dict[str, Any]]:
        """
        Get clock table data.

        Returns a list of clock models with their metadata.
        """
        return data_cache.load_clock_table()

    @app.get("/health", tags=["health"])
    async def health_check() -> dict[str, str]:
        """
        Health check endpoint.

        Returns the health status of the API.
        """
        logger.debug("Health check requested")
        return {
            "status": "healthy",
            "version": settings.app_version,
        }

    @app.get("/api/info", tags=["info"])
    async def get_info() -> dict[str, Any]:
        """
        Get API information.

        Returns basic information about the API.
        """
        return {
            "name": settings.app_name,
            "version": settings.app_version,
            "description": "A comprehensive platform for biological age profiling",
        }

    # Mount static files for SPA (must be last)
    if settings.frontend_dir.exists():
        app.mount(
            "/",
            SPAStaticFiles(directory=str(settings.frontend_dir), html=True),
            name="spa",
        )
        logger.info(f"Mounted frontend from: {settings.frontend_dir}")
    else:
        logger.warning(f"Frontend directory not found: {settings.frontend_dir}")

    logger.info("Application initialized successfully")
    return app


# ============================================================================
# Application Instance
# ============================================================================

app = create_app()


# ============================================================================
# Development Server Entry Point
# ============================================================================

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8009,
        reload=settings.debug,
        log_config=None,  # Use our custom logging
    )
