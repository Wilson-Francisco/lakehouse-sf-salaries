WITH tb_dia_job AS (

    SELECT  DISTINCT t1.IdEmployee,
            t1.BasePay,
            t1.TotalPay,
            t1.TotalPayBenefits, 
            date(t1.DateJob) AS dtJob
    FROM silver.sf_salaries.silver AS t1
    ),

tb_referencia AS (

    SELECT t1.id_funcionario,
            t1.dt_ref
    FROM features_store.sf_salaries.features_salaries AS t1
    WHERE t1.dt_ref <= '2014-06-01'
    ),

tb_group_join (

    SELECT t1.id_funcionario,
            t1.dt_ref,
            t2.dtJob,
            t2.BasePay,
            t2.TotalPay,
            t2.TotalPayBenefits,
            count(t2.idemployee) AS count_jobs

    FROM tb_referencia AS t1
        LEFT JOIN tb_dia_job AS t2
    ON t1.id_funcionario = t2.IdEmployee
    AND t1.dt_ref <= t2.dtJob
    AND t2.dtJob < (DATE(t1.dt_ref) + INTERVAL 6 MONTH)
    
    GROUP BY ALL
),

target_salario AS (

    SELECT t1.id_funcionario,
            t1.dt_ref,
            t1.BasePay,
            t1.TotalPay,
            t1.TotalPayBenefits,
            t1.count_jobs,
            ROUND((COALESCE(t1.TotalPayBenefits, 0.0) / CASE WHEN YEAR(DATE(t1.dtJob)) = 2012 THEN 366.0 ELSE 365.0 END) * 180, 2) AS target_salario_total
    FROM tb_group_join AS t1
)


SELECT t2.id_funcionario,
        t2.nome_funcionario,
        date(t2.dt_entrada) AS dt_entrada,
        t2.dt_ref,
        t2.dias_ativo,
        t2.porcentagem_salario_base_beneficio,
        t2.porcentagem_salario_extra,
        t2.porcentagem_outros_pagamentos,
        t2.porcentagem_beneficios,
        t2.porcentagem_salario_total,
        t2.porcentagem_salario_base,
        t2.desvio_medio_salarial,
        t1.target_salario_total
FROM target_salario AS t1
LEFT JOIN features_store.sf_salaries.features_salaries AS t2
ON t1.id_funcionario = t2.id_funcionario
AND t1.dt_ref = t2.dt_ref
ORDER BY t2.dt_ref

