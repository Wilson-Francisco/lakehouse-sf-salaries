WITH tb_ano_job AS (

    SELECT DISTINCT t1.IdEmployee,
            t1.BasePay,
            t1.TotalPay,
            t1.TotalPayBenefits, 
            t1.DateJob AS dtJob,
            SUM(t1.TotalPay) OVER(PARTITION BY t1.IdEmployee, t1.DateJob) AS SalarioTotal
    FROM silver.sf_salaries.silver AS t1
),

tb_referencia AS (
    SELECT t1.id_funcionario,
            t1.dt_ref
    FROM features_store.sf_salaries.features_salaries AS t1
    WHERE t1.dt_ref <= '2013'
),

tb_group_join AS (
    SELECT t1.id_funcionario,
            t1.dt_ref,
            t2.dtJob,
            t2.SalarioTotal,
            COUNT(t2.IdEmployee) AS qtde_job_salario
    FROM tb_referencia AS t1
    LEFT JOIN tb_ano_job AS t2
    ON t1.id_funcionario = t2.IdEmployee
    AND t1.dt_ref < CAST(t2.dtJob  AS INT)
    AND CAST(t2.dtJob AS INT) = CAST(t1.dt_ref AS INT) + 1
    GROUP BY ALL
), 

tb_target AS (

    SELECT
            t1.id_funcionario,
            t1.dt_ref,
            t2.cargo,
            t2.total_funcionarios_cargo,
            t2.porcentagem_salario_extra,
            t2.porcentagem_outros_pagamentos,
            t2.porcentagem_beneficios,
            t2.porcentagem_salario_base,
            t2.desvio_medio_salarial,
            CASE 
                WHEN t1.qtde_job_salario > 0 THEN ROUND(COALESCE(t1.SalarioTotal - t2.salario_total, 0.0), 2)
                ELSE 0.0 
            END AS target_salario
    FROM tb_group_join AS t1
    LEFT JOIN features_store.sf_salaries.features_salaries AS t2
    ON t1.id_funcionario = t2.id_funcionario
    AND CAST(t2.dt_ref AS INT) = CAST(t1.dt_ref AS INT)
    GROUP BY ALL
    ORDER BY t1.dt_ref
)

SELECT *
FROM tb_target