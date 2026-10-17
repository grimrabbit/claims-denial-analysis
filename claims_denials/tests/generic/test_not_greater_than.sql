{#
    Generic test: fails for any row where column_name is greater than compare_to.
    Rows where either value is null are skipped (null > x is null, not true),
    so suppressed (**) and new (N/A) cells never cause a failure.
#}

{% test not_greater_than(model, column_name, compare_to) %}

select *
from {{ model }}
where {{ column_name }} > {{ compare_to }}

{% endtest %}
