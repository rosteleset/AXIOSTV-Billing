
<FORM action='$SELF_URL' class='form-inline' method='GET' ID='SQLCMD_TABLE_SEARCH' name='SQLCMD_TABLE_SEARCH'>

    <input type=hidden name=index value='$index'>

    <div class='form-group'>
        <label for='TABLES'>_{TABLES}_:</label>
        <input type=text ID=TABLES name=TABLES value='%TABLES%' class='form-control' form='SQLCMD_TABLE_SEARCH'>
    </div>

    <input type=submit name=search value='_{SEARCH}_' class='btn btn-primary' form='SQLCMD_TABLE_SEARCH'>

</FORM>