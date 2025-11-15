CREATE DATABASE IF NOT EXISTS <react_node_app>;   
SHOW DATABASES;
USE <react_node_app>;    

CREATE TABLE IF NOT EXISTS transactions(id INT NOT NULL
AUTO_INCREMENT, amount DECIMAL(10,2), description
VARCHAR(100), PRIMARY KEY(id));    

SHOW TABLES;    

INSERT INTO transactions (amount,description) VALUES 
('400','groceries'),   
('500','fashion');   

SELECT * FROM transactions;