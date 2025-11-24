import requests
import concurrent.futures
import time

# Configuración
URL = "http://localhost:8900/app/api/products"
CONCURRENT_REQUESTS = 100  # Más que el límite del Bulkhead (10)

def call_api(i):
    try:
        start_time = time.time()
        response = requests.get(URL)
        elapsed = time.time() - start_time
        return f"Request {i}: Status {response.status_code} (Time: {elapsed:.2f}s)"
    except Exception as e:
        return f"Request {i}: Failed - {str(e)}"

print(f"--- Iniciando prueba de Bulkhead con {CONCURRENT_REQUESTS} peticiones concurrentes ---")
print(f"Target: {URL}")
OUTPUT_FILE = "bulkhead_test_results.txt"
print(f"Guardando resultados en: {OUTPUT_FILE}")

with open(OUTPUT_FILE, "w") as f:
    f.write(f"--- Iniciando prueba de Bulkhead con {CONCURRENT_REQUESTS} peticiones concurrentes ---\n")
    f.write(f"Target: {URL}\n\n")

    with concurrent.futures.ThreadPoolExecutor(max_workers=CONCURRENT_REQUESTS) as executor:
        # Lanzar todas las peticiones "al mismo tiempo"
        futures = [executor.submit(call_api, i) for i in range(CONCURRENT_REQUESTS)]
        
        for future in concurrent.futures.as_completed(futures):
            result = future.result()
            print(result)
            f.write(result + "\n")

    f.write("\n--- Prueba finalizada ---\n")

print("--- Prueba finalizada ---")
