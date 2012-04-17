delete from salor1_production.cues where 1;
delete from salor_development.cues where 1;
delete from salor_development.nodes where is_self IS FALSE;
delete from salor1_production.nodes where is_self IS FALSE;
delete from salor1_production.node_messages where 1;
delete from salor_development.node_messages where 1;
