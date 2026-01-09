FROM python:3.11-slim

WORKDIR /ContentFilter

RUN pip install --no-cache-dir \
    torch==2.9.1+cpu \
    --index-url https://download.pytorch.org/whl/cpu

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "main.py"]