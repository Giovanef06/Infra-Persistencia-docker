-- Script de inicialização do banco de dados
-- Cenário 1 — Persistência com MySQL

CREATE DATABASE IF NOT EXISTS empresa;

USE empresa;

CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100),
  email VARCHAR(100),
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO usuarios (nome, email) VALUES
  ('Carlos', 'carlos@gmail.com'),
  ('Ana', 'ana@gmail.com'),
  ('Marcos', 'marcos@gmail.com');
