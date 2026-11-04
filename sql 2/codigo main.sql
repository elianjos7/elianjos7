DROP TABLE IF EXISTS mensalidade CASCADE;
DROP TABLE IF EXISTS matricula CASCADE;
DROP TABLE IF EXISTS locacao CASCADE;
DROP TABLE IF EXISTS turma CASCADE;
DROP TABLE IF EXISTS quadra CASCADE;
DROP TABLE IF EXISTS professor CASCADE;
DROP TABLE IF EXISTS plano CASCADE;
DROP TABLE IF EXISTS nivel_turma CASCADE;
DROP TABLE IF EXISTS forma_pagamento CASCADE;
DROP TABLE IF EXISTS aluno CASCADE;

CREATE TABLE aluno (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(11) NOT NULL UNIQUE,
    data_nascimento DATE,
    sexo VARCHAR(20),
    telefone VARCHAR(15),
    email VARCHAR(100) UNIQUE,
    data_cadastro DATE NOT NULL,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE forma_pagamento (
    id SERIAL PRIMARY KEY,
    descricao VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE nivel_turma (
    id SERIAL PRIMARY KEY,
    descricao VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE plano (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    descricao VARCHAR(200),
    frequencia_semanal INT NOT NULL,
    duracao_meses INT NOT NULL,
    valor NUMERIC(10, 2) NOT NULL,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE professor (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(11) NOT NULL UNIQUE,
    telefone VARCHAR(15),
    email VARCHAR(100) UNIQUE,
    especialidade VARCHAR(100),
    data_contratacao DATE NOT NULL,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE quadra (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    coberta BOOLEAN DEFAULT FALSE,
    iluminacao BOOLEAN DEFAULT FALSE,
    valor_hora NUMERIC(10, 2) NOT NULL,
    ativa BOOLEAN DEFAULT TRUE
);

CREATE TABLE turma (
    id SERIAL PRIMARY KEY,
    id_professor INT NOT NULL,
    id_nivel INT NOT NULL,
    nome VARCHAR(50) NOT NULL,
    dia_semana VARCHAR(20) NOT NULL,
    horario_inicio TIME NOT NULL,
    horario_fim TIME NOT NULL,
    vagas_maximas INT NOT NULL,
    ativa BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (id_professor) REFERENCES professor(id) ON DELETE CASCADE,
    FOREIGN KEY (id_nivel) REFERENCES nivel_turma(id) ON DELETE CASCADE
);

CREATE TABLE locacao (
    id SERIAL PRIMARY KEY,
    id_aluno INT NOT NULL,
    id_quadra INT NOT NULL,
    id_forma_pagamento INT NOT NULL,
    data_locacao DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fim TIME NOT NULL,
    valor_total NUMERIC(10, 2) NOT NULL,
    status VARCHAR(30) DEFAULT 'Confirmada',
    FOREIGN KEY (id_aluno) REFERENCES aluno(id) ON DELETE CASCADE,
    FOREIGN KEY (id_quadra) REFERENCES quadra(id) ON DELETE CASCADE,
    FOREIGN KEY (id_forma_pagamento) REFERENCES forma_pagamento(id) ON DELETE RESTRICT
);

CREATE TABLE matricula (
    id SERIAL PRIMARY KEY,
    id_aluno INT NOT NULL,
    id_turma INT NOT NULL,
    id_plano INT NOT NULL,
    data_matricula DATE NOT NULL,
    data_inicio DATE NOT NULL,
    data_termino DATE,
    status VARCHAR(30) DEFAULT 'Ativa',
    FOREIGN KEY (id_aluno) REFERENCES aluno(id) ON DELETE CASCADE,
    FOREIGN KEY (id_turma) REFERENCES turma(id) ON DELETE CASCADE,
    FOREIGN KEY (id_plano) REFERENCES plano(id) ON DELETE CASCADE
);

CREATE TABLE mensalidade (
    id SERIAL PRIMARY KEY,
    id_matricula INT NOT NULL,
    id_forma_pagamento INT NOT NULL,
    mes_referencia VARCHAR(7) NOT NULL,
    data_vencimento DATE NOT NULL,
    data_pagamento DATE,
    valor NUMERIC(10, 2) NOT NULL,
    status VARCHAR(30) DEFAULT 'Pendente',
    FOREIGN KEY (id_matricula) REFERENCES matricula(id) ON DELETE CASCADE,
    FOREIGN KEY (id_forma_pagamento) REFERENCES forma_pagamento(id) ON DELETE RESTRICT
);

INSERT INTO forma_pagamento (descricao) VALUES ('Cartão de Crédito'), ('PIX'), ('Dinheiro');

INSERT INTO nivel_turma (descricao) VALUES ('Iniciante');

INSERT INTO aluno (nome, cpf, data_nascimento, sexo, telefone, email, data_cadastro, ativo) 
VALUES ('João Silva', '11111111111', '1990-01-01', 'M', '11999990001', 'joao@email.com', CURRENT_DATE, TRUE);

INSERT INTO professor (nome, cpf, telefone, email, especialidade, data_contratacao, ativo) 
VALUES ('Carlos Souza', '22222222222', '11888880001', 'carlos@email.com', 'Tênis', CURRENT_DATE, TRUE);

INSERT INTO quadra (nome, coberta, iluminacao, valor_hora, ativa) 
VALUES ('Quadra 01', TRUE, TRUE, 100.00, TRUE);

INSERT INTO plano (nome, descricao, frequencia_semanal, duracao_meses, valor, ativo) 
VALUES ('Plano Mensal', '1x por semana', 1, 1, 150.00, TRUE);

INSERT INTO turma (id_professor, id_nivel, nome, dia_semana, horario_inicio, horario_fim, vagas_maximas, ativa) 
VALUES (1, 1, 'Turma A', 'Segunda', '08:00', '09:00', 10, TRUE);

INSERT INTO matricula (id_aluno, id_turma, id_plano, data_matricula, data_inicio, data_termino, status) 
VALUES (1, 1, 1, '2023-01-01', '2023-01-10', '2023-07-10', 'Ativa');

INSERT INTO mensalidade (id_matricula, id_forma_pagamento, mes_referencia, data_vencimento, data_pagamento, valor, status) 
VALUES (1, 1, '2023-01', '2023-01-15', '2023-01-10', 150.00, 'Pago');

INSERT INTO locacao (id_aluno, id_quadra, id_forma_pagamento, data_locacao, hora_inicio, hora_fim, valor_total, status) 
VALUES (1, 1, 1, '2023-02-01', '18:00', '19:00', 100.00, 'Finalizada');


SELECT a.nome AS aluno, p.nome AS plano
FROM aluno a
JOIN matricula mat ON a.id = mat.id_aluno
JOIN plano p ON mat.id_plano = p.id
WHERE mat.status = 'Ativa';

SELECT pr.nome AS professor, COUNT(DISTINCT mat.id_aluno) AS total_alunos
FROM professor pr
LEFT JOIN turma t ON pr.id = t.id_professor
LEFT JOIN matricula mat ON t.id = mat.id_turma
GROUP BY pr.id, pr.nome
ORDER BY total_alunos DESC;

SELECT DISTINCT a.id, a.nome
FROM aluno a
JOIN matricula m ON a.id = m.id_aluno
WHERE NOT EXISTS (
    SELECT 1 FROM mensalidade mes 
    WHERE mes.id_matricula = m.id AND mes.status = 'Pago'
);

SELECT DISTINCT a.id, a.nome
FROM aluno a
JOIN matricula mat ON a.id = mat.id_aluno
JOIN plano p ON mat.id_plano = p.id
WHERE p.nome ILIKE '%Anual%'
  AND NOT EXISTS (
      SELECT 1 FROM locacao l WHERE l.id_aluno = a.id
  );

SELECT t.id, t.nome, COUNT(mat.id) AS total_alunos
FROM turma t
LEFT JOIN matricula mat ON t.id = mat.id_turma AND mat.status = 'Ativa'
GROUP BY t.id, t.nome
HAVING COUNT(mat.id) < 5;

SELECT 
    pr.nome AS professor, 
    MAKE_INTERVAL(secs => AVG(EXTRACT(EPOCH FROM (t.horario_fim - t.horario_inicio)))) AS duracao_media
FROM professor pr
JOIN turma t ON pr.id = t.id_professor
GROUP BY pr.id, pr.nome;

SELECT p.nome AS plano, SUM(m.valor) AS faturamento_total
FROM plano p
JOIN matricula mat ON p.id = mat.id_plano
JOIN mensalidade m ON mat.id = m.id_matricula
WHERE m.status = 'Pago'
GROUP BY p.id, p.nome;

SELECT mes_referencia, SUM(valor) AS total_inadimplente
FROM mensalidade
WHERE status = 'Pendente' AND data_vencimento < CURRENT_DATE
GROUP BY mes_referencia
ORDER BY mes_referencia;

SELECT a.nome, m.valor, m.data_vencimento
FROM aluno a
JOIN matricula mat ON a.id = mat.id_aluno
JOIN mensalidade m ON mat.id = m.id_matricula
WHERE m.status = 'Pendente' AND m.data_vencimento < CURRENT_DATE;

SELECT q.nome AS quadra, SUM(l.valor_total) AS receita_total
FROM quadra q
JOIN locacao l ON q.id = l.id_quadra
WHERE l.data_locacao >= '2024-01-01' AND l.data_locacao <= '2024-01-31'
GROUP BY q.id, q.nome;

SELECT a.id, a.nome, COUNT(mat.id) AS total_matriculas_ativas
FROM aluno a
JOIN matricula mat ON a.id = mat.id_aluno
WHERE mat.status = 'Ativa'
GROUP BY a.id, a.nome
HAVING COUNT(mat.id) > 1;

SELECT q.nome AS quadra,
       (SELECT COUNT(*) FROM locacao l WHERE l.id_quadra = q.id) AS total_locacoes
FROM quadra q;

SELECT p.nome AS plano, COUNT(m.id) AS qtd_pendentes
FROM plano p
LEFT JOIN matricula mat ON p.id = mat.id_plano
LEFT JOIN mensalidade m ON mat.id = m.id_matricula AND m.status = 'Pendente'
GROUP BY p.id, p.nome;

SELECT p.id, p.nome
FROM professor p
LEFT JOIN turma t ON p.id = t.id_professor
WHERE t.id IS NULL;

SELECT q.nome AS quadra, SUM(l.valor_total) AS receita_total
FROM quadra q
JOIN locacao l ON q.id = l.id_quadra
GROUP BY q.id, q.nome
HAVING SUM(l.valor_total) > 5000.00;

SELECT pr.nome AS professor, SUM(mes.valor) AS receita_total
FROM professor pr
JOIN turma t ON pr.id = t.id_professor
JOIN matricula mat ON t.id = mat.id_turma
JOIN mensalidade mes ON mat.id = mes.id_matricula
WHERE mes.status = 'Pago'
GROUP BY pr.id, pr.nome;

SELECT pr.nome AS professor, SUM(mes.valor) AS receita_total
FROM professor pr
JOIN turma t ON pr.id = t.id_professor
JOIN matricula mat ON t.id = mat.id_turma
JOIN mensalidade mes ON mat.id = mes.id_matricula
WHERE mes.status = 'Pago'
GROUP BY pr.id, pr.nome;

SELECT AVG(valor) AS ticket_medio
FROM mensalidade
WHERE status = 'Pago' 
  AND data_pagamento >= CURRENT_DATE - INTERVAL '3 months';

SELECT t.id, t.nome, t.vagas_maximas, COUNT(mat.id) AS total_alunos
FROM turma t
JOIN matricula mat ON t.id = mat.id_turma
WHERE mat.status = 'Ativa'
GROUP BY t.id, t.nome, t.vagas_maximas
HAVING COUNT(mat.id) >= 12

SELECT a.nome AS aluno, MAX(l.data_locacao) AS ultima_locacao
FROM aluno a
LEFT JOIN locacao l ON a.id = l.id_aluno
GROUP BY a.id, a.nome;
