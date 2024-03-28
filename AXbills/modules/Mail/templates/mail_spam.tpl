<form action=$SELF_URL METHOD=POST>
<input type=hidden name='index' value='$index'>
<input type=hidden name='ID' value='$FORM{chg}'>
<table class=form>

<tr><td>_{REQUIRED_SCORE}_:</td><td>%REQUIRED_SCORE_SEL%</td></tr>
<tr><td>_{REWRITE_HEADER}_:</td><td><input type=text name=REWRITE_HEADER value='%REWRITE_HEADER%'></td></tr>
<tr><td>_{REPORT_SAFE}_:</td><td>%REPORT_SAFE_SEL%</td></tr>
<tr><td>_{USER_IN_WHITELIST}_:</td><td><input type=text name=USER_IN_WHITELIST value='%USER_IN_WHITELIST%'></td></tr>
<tr><td>_{USER_IN_BLACKLIST}_:</td><td><input type=text name=USER_IN_BLACKLIST value='%USER_IN_BLACKLIST%'></td></tr>
<tr><td>_{OK_LOCALES}_:</td><td><input type=text name=OK_LOCALES value='%OK_LOCALES%'></td></tr>
<tr><th colspan=2 bgcolor='$_COLORS[0]'>_{AUTO_LEARN}_</th></tr>


<tr><td>_{USE_BAYES}_:</td><td><input type=checkbox name=USE_BAYES value='1', %USE_BAYES%></td></tr>
<tr><td>_{BAYES_AUTO_LEARN}_:</td><td><input type=checkbox name=BAYES_AUTO_LEARN value='1' %BAYES_AUTO_LEARN%></td></tr>
<tr><td>_{BAYES_AUTO_LEARN_THRESHOLD_NONSPAM}_:</td><td>%BAYES_AUTO_LEARN_THRESHOLD_NONSPAM_SEL%</td></tr>
<tr><td>_{BAYES_AUTO_LEARN_THRESHOLD_SPAM}_:</td><td>%BAYES_AUTO_LEARN_THRESHOLD_SPAM_SEL%</td></tr>
<tr><td>_{USE_AUTO_WHITELIST}_:</td><td><input type=checkbox name=USE_AUTO_WHITELIST value='1' %USE_AUTO_WHITELIST%></td></tr>
<tr><td>_{AUTO_WHITELIST_FACTOR}_:</td><td>%AUTO_WHITELIST_FACTOR_SEL%</td></tr>

<tr><th colspan=2 bgcolor='$_COLORS[0]'>_{NETWORK_CHECK}_</th></tr>

<tr><td>_{USE_DCC}_</td><td><input type=checkbox name=USE_DCC value='1' %USE_DCC%></td></tr>
<tr><td>_{USE_PYZOR}_</td><td><input type=checkbox name=USE_PYZOR value='1' %USE_PYZOR%></td></tr>
<tr><td>_{USE_RAZOR2}_</td><td><input type=checkbox name=USE_RAZOR2 value='1' %USE_RAZOR2%></td></tr>

<!--
<tr><td>ID:</td><td> %ID%</td></tr>
<tr><td>_{USER}_ (\$GLOBAL - _{ALL}_):</td><td><input type=text name=USER_NAME value='%USER_NAME%'></td></tr>
<tr><td>_{OPTIONS}_:</td><td><input type=text name=PREFERENCE value='%PREFERENCE%'></td></tr>
<tr><td>_{VALUE}_:</td><td><input type=text name=VALUE value='%VALUE%'></td></tr>
<tr><td>_{COMMENTS}_:</td><td><input type=text name=COMMENTS value='%COMMENTS%'></td></tr>
<tr><td>_{ADDED}_:</td><td>%ADD%</td></tr>
<tr><td>_{CHANGED}_:</td><td>%CHANGED%</td></tr>
-->

<tr><th class=even colspan=2><input type=submit name=%ACTION% value='%LNG_ACTION%'></th></tr>
</table>

</form>
