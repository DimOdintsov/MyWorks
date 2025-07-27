<style type="text/css">
	table { 
		width: 100%; 
		border-collapse: separate; 
		border-bottom: 2px solid #fff; 
		caption-side: bottom;
	}
	.table { 
		border-collapse: separate; 
		border-bottom: 0px solid #fff; 
		caption-side: bottom;
	}

	.top {
		background-color: #4f81bd;
		padding:5px;
		color:#fff;
		font-weight: bold;
		text-align:center;
		border-left:2px solid #fff;
		border-top:2px solid #fff; 
	}
	.top 1 {
		background-color: #4f81bd;
		padding:0px;
		margin:0px
		color:#fff;
		font-weight: bold;
		text-align:center;
		border-left:0px solid #fff;
		border-top:0px solid #fff;
		}

	.td0 { 
		margin: 0px; 
		padding: 0px; 
		vertical-align: top; 
		background: #F2F2F2; 
		color: #000;
		font-size: 12px;
		}

	.other {
		padding:5px;
		color:#777;
		text-align:center;
		border-left:2px solid #fff;
		border-top:2px solid #fff;
	}
	.other1 {
		padding:5px;
		margin:0px;
		color:#F14C38;
		text-align:left;
		border-left:0px solid #fff;
		border-top:0px solid #fff;
	}

	td { 
		margin: 3px; 
		padding: 5px; 
		vertical-align: top; 
		background: #F2F2F2; 
		color: #000;
		font-size: 12px;
		}
		
	thead th {
		background: #903; 
		color:#fefdcf; 
		text-align: center; 
		font-weight: bold; 
		padding: 3px;
		}
		
	th {
		padding: 3px;
		}
		
	tbody th:hover {
		background-color: #fefdcf;
		paddign:20px;	
		}
		
	th a:link, th a:visited {
		color:#903; 
		font-weight: normal; 
		text-decoration: none; 
		border-bottom:1px dotted #c93;
		}

		
	tbody td a:link {color: #903;}
	tbody td a:visited {color:#633;}
</style>
<table>
 
  <tr>
  #set ($column_count = 0)
  #foreach ($column in $columns)
    <td class='top'>$!column</td>
  #end
  </tr>
 
  #foreach ($row in $result)
    <tr>
    #foreach ($column in $row)
      <td>$!column</td>
    #end
    </tr>
  #end
 
</table>