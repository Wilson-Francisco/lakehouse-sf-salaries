WITH base_ativa AS (
    SELECT 
        '{dt_ref}' AS dt_ref,
        t1.IdEmployee,
        -- pegando o cargo mais recente
        t1.JobTitle AS cargo,
        ROW_NUMBER() OVER (PARTITION BY t1.IdEmployee ORDER BY t1.DateJob DESC) AS rn_cargo
    FROM silver.sf_salaries.silver AS t1
    WHERE t1.DateJob <= '{dt_ref}'
),
base_desduplicada AS (
    -- garantir apenas 1 linha por funcionário com seu cargo definitivo
    SELECT 
        dt_ref, 
        IdEmployee, 
        cargo
    FROM base_ativa
    WHERE rn_cargo = 1
) 

SELECT 
    t1.dt_ref,
    t1.IdEmployee AS id_funcionario,
    t1.cargo,
    COUNT(t1.IdEmployee) OVER(PARTITION BY t1.cargo) AS total_funcionarios_cargo,
    SUM(t2.TotalPay) OVER(PARTITION BY t1.cargo) AS salario_total,
    t2.TotalPayBenefits AS salario_total_beneficios,
    
    CASE 
        WHEN t2.TotalPayBenefits > 0 THEN ROUND((t2.BasePay / t2.TotalPayBenefits) * 100, 2)
        ELSE 0.0 
    END AS porcentagem_salario_base_beneficio, 
    CASE 
        WHEN t2.TotalPay > 0 THEN ROUND((t2.OvertimePay / t2.TotalPay) * 100, 2)
        ELSE 0.0 
    END AS porcentagem_salario_extra,
    CASE 
        WHEN t2.TotalPay > 0 THEN ROUND((t2.OtherPay / t2.TotalPay) * 100, 2)
        ELSE 0.0 
    END AS porcentagem_outros_pagamentos,
    CASE 
        WHEN t2.TotalPay > 0 THEN ROUND((t2.Benefits / t2.TotalPay) * 100, 2)
        ELSE 0.0 
    END AS porcentagem_beneficios,
    CASE 
        WHEN t2.TotalPay > 0 THEN ROUND((t2.BasePay / t2.TotalPay) * 100, 2)
        ELSE 0.0 
    END AS porcentagem_salario_base,
    
    -- Desvio comparando TotalPay com a Média de TotalPay do mesmo cargo na janela analítica
    CASE 
        WHEN t2.TotalPay > 0 THEN 
            ROUND(((AVG(t2.TotalPay) OVER(PARTITION BY t1.cargo) - t2.TotalPay) / NULLIF(AVG(t2.TotalPay) OVER(PARTITION BY t1.cargo), 0)) * 100, 2)
        ELSE 0.0 
    END AS desvio_medio_salarial
FROM base_desduplicada AS t1
LEFT JOIN silver.sf_salaries.silver AS t2 
  ON t1.IdEmployee = t2.IdEmployee 
  AND t2.DateJob <= '{dt_ref}';