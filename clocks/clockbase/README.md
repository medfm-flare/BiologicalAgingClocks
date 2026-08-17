# ClockBase

ClockBase is a web application for analyzing and visualizing biological age predictions from DNA methylation data and RNA-Seq data.
It provides an interface to upload datasets, view predictions, and explore metadata associated with GEO Series.

## Run
To run the application locally, follow these steps:
1. Clone the repository:
    ```bash
    git clone https://github.com/Gladyshev-Lab/clockbase
    cd clockbase
    ```
2. Navigate to the frontend directory, and install dependencies:
    ```bash
    cd ../frontend
    npm install
    ```
3. Build frontend assets:
    ```bash
    npm run build
4. Open new terminal and navigate to the backend directory and install dependencies:
    ```bash
    cd backend
    uv venv .venv -p 3.13
    source .venv/bin/activate  # On Windows use `.venv\Scripts\activate`
    uv pip install -r requirements.txt
    ```
5. Start the server:
    ```bash
    uv uvicorn main:app --host 0.0.0.0 --port 8009
    ```
6. Open your web browser and navigate to `http://localhost:8009` to access the application.
