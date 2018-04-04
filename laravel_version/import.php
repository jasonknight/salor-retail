<?php
$schema_lines = file("../rails_version/salor-retail/db/schema.rb");
$resources = array();
$ctable = null;
for ($i = 0; $i < count($schema_lines); $i++ ) 
{
	$line = $schema_lines[$i];
	if ( preg_match("/^\s+create_table \"(.+)\",/",$line,$m) )
	{
		if ( preg_match("/^spree_/",$m[1]) )
		{
			continue;
		}
		if ( $m[1] == "stamp_collections") 
		{
			continue;
		}
		$ctable = $m[1];
	}
	if ( preg_match("/^\s+end$/",$line) && $ctable != null)
	{ 
		$ctable = null;
	}
	if (preg_match("/\s+t\.([\w]+)\s+\"([\w_]+)\"\s+/",$line,$m) && $ctable != null)
	{
		if (! isset($resources[$ctable] ) )
		{
			$resources[$ctable] = array('fields' => array(), 'indices' => array());
		}
		$resources[$ctable]['fields'][$m[2]] = $m[1];
	}
}

foreach ($resources as $kls=>$desc)
{
	if ( $kls[strlen($kls)-1] == 's') 
	{
		$kls_name = substr($kls,0,strlen($kls)-1);
	}
	else
	{
		$kls_name = $kls;
	}
	$path = "../rails_version/salor-retail/app/models/$kls_name.rb";
	$kls_name = str_replace(' ','',ucwords(str_replace('_',' ',$kls_name)));
	$desc['class'] = $kls_name;
	$resources[$kls] = $desc;
	if (file_exists($path)) 
	{
		$resources['model_path'] = $path;
	}
	else
	{
		$resources['model_path'] = 'none';
	}

}









print_r($resources);
