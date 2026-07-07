WITH base_ativa AS (

    SELECT 
            '{dt_ref}' AS dt_ref,
            t1.IdEmployee,
            t1.EmployeeName AS nome_funcionario,
            t1.JobTitle AS cargo,
            min(t1.DateJob) AS dt_entrada,
            datediff('{dt_ref}', min(t1.DateJob)) AS dias_ativo
    FROM silver.sf_salaries.silver AS t1
    WHERE t1.DateJob >= '{dt_ref}' - INTERVAL 90 day
    AND t1.DateJob <= '{dt_ref}'
    GROUP BY ALL
)

SELECT t1.dt_ref,
        t2.IdEmployee As id_funcionario,
        t1.nome_funcionario,
        t1.dt_entrada,
        t1.dias_ativo,
        CASE 
            WHEN t2.TotalPayBenefits > 0 THEN ROUND((t2.BasePay / t2.TotalPayBenefits) *100, 2)
            ELSE 0.0 
        END AS porcentagem_salario_base_beneficio, 
        CASE 
            WHEN t2.TotalPay > 0 THEN ROUND((t2.OvertimePay / t2.TotalPay) *100, 2)
            ELSE 0.0 
        END AS porcentagem_salario_extra,
        CASE 
            WHEN t2.TotalPay > 0 THEN ROUND((t2.OtherPay / t2.TotalPay) *100, 2)
            ELSE 0.0 
        END AS porcentagem_outros_pagamentos,
        CASE 
            WHEN t2.TotalPay > 0 THEN ROUND((t2.Benefits / t2.TotalPay) *100, 2)
            ELSE 0.0 
        END AS porcentagem_beneficios,
        CASE 
            WHEN t2.TotalPay > 0 THEN ROUND((t2.TotalPay / t2.TotalPayBenefits) *100, 2)
            ELSE 0.0 
        END AS porcentagem_salario_total,
        CASE 
            WHEN t2.TotalPay > 0 THEN ROUND((t2.BasePay / t2.TotalPay) *100, 2)
            ELSE 0.0 
        END AS porcentagem_salario_base,
        CASE 
            WHEN t2.TotalPay > 0 THEN ROUND(((AVG(t2.TotalPay) OVER() - t2.BasePay)/AVG(t2.TotalPay) OVER()) *100, 2)
            ELSE 0.0 
        END AS desvio_medio_salarial

       
FROM base_ativa AS t1
LEFT JOIN silver.sf_salaries.silver AS t2
ON t1.IdEmployee = t2.IdEmployee

WHERE t2.DateJob >= '{dt_ref}' - INTERVAL 90 day
AND t2.DateJob <= '{dt_ref}'