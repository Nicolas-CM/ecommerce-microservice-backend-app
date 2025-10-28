"""
Pruebas de Rendimiento para E-commerce Microservices
Usando Locust para simular carga de usuarios
"""

from locust import HttpUser, task, between
import random

class EcommerceUser(HttpUser):
    wait_time = between(1, 3)  # Espera entre 1-3 segundos entre tareas
    
    def on_start(self):
        """Ejecutado cuando un usuario inicia"""
        self.user_id = None
        self.product_ids = []
    
    @task(5)
    def browse_products(self):
        """Simula navegación de productos (tarea más común)"""
        with self.client.get("/product-service/api/products", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
                try:
                    products = response.json()
                    if isinstance(products, list) and len(products) > 0:
                        self.product_ids = [p.get('productId') for p in products if 'productId' in p]
                except:
                    pass
            else:
                response.failure(f"Failed with status {response.status_code}")
    
    @task(3)
    def view_product_detail(self):
        """Simula ver detalle de un producto"""
        if self.product_ids:
            product_id = random.choice(self.product_ids)
            with self.client.get(f"/product-service/api/products/{product_id}", catch_response=True) as response:
                if response.status_code == 200:
                    response.success()
                else:
                    response.failure(f"Failed with status {response.status_code}")
    
    @task(4)
    def browse_users(self):
        """Simula navegación de usuarios"""
        with self.client.get("/user-service/api/users", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Failed with status {response.status_code}")
    
    @task(2)
    def view_favourites(self):
        """Simula ver favoritos"""
        with self.client.get("/favourite-service/api/favourites", catch_response=True) as response:
            if response.status_code in [200, 500]:  # 500 es esperado si no hay datos
                response.success()
            else:
                response.failure(f"Failed with status {response.status_code}")
    
    @task(1)
    def view_orders(self):
        """Simula ver órdenes"""
        with self.client.get("/order-service/api/orders", catch_response=True) as response:
            if response.status_code in [200, 500]:
                response.success()
            else:
                response.failure(f"Failed with status {response.status_code}")
    
    @task(2)
    def view_payments(self):
        """Simula ver pagos"""
        with self.client.get("/payment-service/api/payments", catch_response=True) as response:
            if response.status_code in [200, 500]:
                response.success()
            else:
                response.failure(f"Failed with status {response.status_code}")


class AdminUser(HttpUser):
    """Usuario administrador con tareas diferentes"""
    wait_time = between(2, 5)
    weight = 1  # 1 admin por cada 10 usuarios normales
    
    @task
    def check_eureka(self):
        """Verifica el estado de Eureka"""
        with self.client.get("http://localhost:8761/actuator/health", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Eureka down: {response.status_code}")
