"""
Pruebas de Rendimiento para E-commerce Microservices
Usando Locust para simular carga de usuarios concurrentes

Arquitectura: Todas las peticiones van a través de API Gateway en /app/api/*
"""

from locust import HttpUser, task, between
import random
import json

class EcommerceUser(HttpUser):
    """Usuario típico navegando y comprando en el e-commerce"""
    wait_time = between(1, 3)  # Espera entre 1-3 segundos entre tareas
    
    def on_start(self):
        """Ejecutado cuando un usuario inicia - Datos de sesión"""
        self.user_id = None
        self.product_ids = [1, 2, 3, 4, 5]  # IDs de productos por defecto
        self.jwt_token = None
    
    @task(10)
    def browse_products(self):
        """Simula navegación de productos (tarea más común - endpoint público)"""
        with self.client.get("/app/api/products", 
                            name="Browse Products",
                            catch_response=True) as response:
            if response.status_code == 200:
                response.success()
                try:
                    data = response.json()
                    # Puede venir como array directo o como {collection: [...]}
                    products = data if isinstance(data, list) else data.get('collection', [])
                    if len(products) > 0:
                        self.product_ids = [p.get('productId') for p in products if 'productId' in p]
                except Exception as e:
                    pass
            else:
                response.failure(f"Failed with status {response.status_code}")
    
    @task(8)
    def view_product_detail(self):
        """Simula ver detalle de un producto específico (endpoint público)"""
        if self.product_ids:
            product_id = random.choice(self.product_ids)
            with self.client.get(f"/app/api/products/{product_id}", 
                                name="View Product Detail",
                                catch_response=True) as response:
                if response.status_code == 200:
                    response.success()
                else:
                    response.failure(f"Failed with status {response.status_code}")
    
    @task(3)
    def browse_categories(self):
        """Simula navegación de categorías (endpoint público)"""
        with self.client.get("/app/api/categories",
                            name="Browse Categories",
                            catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Failed with status {response.status_code}")
    
    @task(2)
    def view_users(self):
        """Simula vista de usuarios (endpoint protegido - esperamos 401)"""
        with self.client.get("/app/api/users",
                            name="View Users (Protected)",
                            catch_response=True) as response:
            # 200 OK si tiene token, 401/403 si no tiene token (esperado)
            if response.status_code in [200, 401, 403]:
                response.success()
            else:
                response.failure(f"Unexpected status {response.status_code}")
    
    @task(2)
    def view_orders(self):
        """Simula ver órdenes (endpoint protegido)"""
        with self.client.get("/app/api/orders",
                            name="View Orders (Protected)",
                            catch_response=True) as response:
            if response.status_code in [200, 401, 403]:
                response.success()
            else:
                response.failure(f"Unexpected status {response.status_code}")
    
    @task(2)
    def view_payments(self):
        """Simula ver pagos (endpoint protegido)"""
        with self.client.get("/app/api/payments",
                            name="View Payments (Protected)",
                            catch_response=True) as response:
            if response.status_code in [200, 401, 403]:
                response.success()
            else:
                response.failure(f"Unexpected status {response.status_code}")
    
    @task(1)
    def view_carts(self):
        """Simula ver carritos (endpoint protegido)"""
        with self.client.get("/app/api/carts",
                            name="View Carts (Protected)",
                            catch_response=True) as response:
            if response.status_code in [200, 401, 403]:
                response.success()
            else:
                response.failure(f"Unexpected status {response.status_code}")
    
    @task(1)
    def view_shippings(self):
        """Simula ver envíos (endpoint protegido)"""
        with self.client.get("/app/api/shippings",
                            name="View Shippings (Protected)",
                            catch_response=True) as response:
            if response.status_code in [200, 401, 403]:
                response.success()
            else:
                response.failure(f"Unexpected status {response.status_code}")


class AuthenticatedUser(HttpUser):
    """Usuario autenticado que realiza operaciones completas"""
    wait_time = between(2, 5)
    weight = 2  # 2 usuarios autenticados por cada 10 usuarios normales
    
    def on_start(self):
        """Autenticar usuario al inicio"""
        self.product_ids = [1, 2, 3, 4, 5]
        self.jwt_token = None
        self.authenticate()
    
    def authenticate(self):
        """Intenta autenticarse con credenciales de prueba"""
        login_data = {
            "username": "admin",
            "password": "admin"
        }
        
        with self.client.post("/app/api/authenticate",
                             json=login_data,
                             name="Authenticate",
                             catch_response=True) as response:
            if response.status_code == 200:
                try:
                    data = response.json()
                    self.jwt_token = data.get('jwtToken')
                    response.success()
                except:
                    response.failure("No JWT token in response")
            else:
                response.failure(f"Authentication failed: {response.status_code}")
    
    def get_auth_headers(self):
        """Retorna headers con token de autenticación"""
        if self.jwt_token:
            return {"Authorization": f"Bearer {self.jwt_token}"}
        return {}
    
    @task(5)
    def browse_products_authenticated(self):
        """Navegar productos como usuario autenticado"""
        with self.client.get("/app/api/products",
                            headers=self.get_auth_headers(),
                            name="Browse Products (Auth)",
                            catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Failed: {response.status_code}")
    
    @task(3)
    def view_my_orders(self):
        """Ver mis órdenes como usuario autenticado"""
        with self.client.get("/app/api/orders",
                            headers=self.get_auth_headers(),
                            name="View My Orders",
                            catch_response=True) as response:
            if response.status_code in [200, 404]:
                response.success()
            else:
                response.failure(f"Failed: {response.status_code}")
    
    @task(2)
    def view_my_carts(self):
        """Ver mis carritos como usuario autenticado"""
        with self.client.get("/app/api/carts",
                            headers=self.get_auth_headers(),
                            name="View My Carts",
                            catch_response=True) as response:
            if response.status_code in [200, 404]:
                response.success()
            else:
                response.failure(f"Failed: {response.status_code}")
    
    @task(2)
    def view_my_favourites(self):
        """Ver mis favoritos como usuario autenticado"""
        with self.client.get("/app/api/favourites",
                            headers=self.get_auth_headers(),
                            name="View My Favourites",
                            catch_response=True) as response:
            if response.status_code in [200, 404]:
                response.success()
            else:
                response.failure(f"Failed: {response.status_code}")


class AdminUser(HttpUser):
    """Usuario administrador realizando tareas de monitoreo"""
    wait_time = between(5, 10)
    weight = 1  # 1 admin por cada 10 usuarios normales
    
    @task(3)
    def check_api_gateway_health(self):
        """Verifica el estado del API Gateway"""
        with self.client.get("/app/actuator/health",
                            name="API Gateway Health",
                            catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Gateway unhealthy: {response.status_code}")
    
    @task(1)
    def monitor_products(self):
        """Monitorear catálogo de productos"""
        with self.client.get("/app/api/products",
                            name="Admin - Monitor Products",
                            catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Failed: {response.status_code}")
    
    @task(1)
    def monitor_users(self):
        """Monitorear usuarios (requiere autenticación de admin)"""
        with self.client.get("/app/api/users",
                            name="Admin - Monitor Users",
                            catch_response=True) as response:
            # 200 si autenticado, 401/403 si no
            if response.status_code in [200, 401, 403]:
                response.success()
            else:
                response.failure(f"Unexpected: {response.status_code}")
