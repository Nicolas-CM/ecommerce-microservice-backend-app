
-- Update admin password to known value and promote to ROLE_ADMIN
UPDATE credentials 
SET password = '$2a$10$/Bfu6MpFTUvrHdc1I8sbtuy/udBHKHQVO3SrwwXGOVIGl81c78YF2',
    role = 'ROLE_ADMIN'
WHERE username = 'admin';
