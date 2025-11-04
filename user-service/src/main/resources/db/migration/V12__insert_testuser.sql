
-- Insert testuser for testing
INSERT INTO users (first_name, last_name) VALUES ('test', 'user');

INSERT INTO credentials (user_id, username, password, role, is_enabled) 
VALUES (5, 'testuser', '$2a$10$ZnG90cXmrLndp8FRsbyxE.n.GVFyyzH/d0fGnea9UaD1GQQB8MoIu', 'ROLE_ADMIN', true);
