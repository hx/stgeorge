require 'sinatra'

get '/ibank' do
  redirect '/ibank/loginPage.action', 302
end

get '/ibank/loginPage.action' do
  <<-END
    <form name="logonForm" action="logonAction.action" method="POST">
      <input type="text" name="userId"/>
      <input type="text" name="securityNumber"/>
      <input type="text" name="password"/>
      <input type="submit" value="Login"/>
    </form>
  END
end

post '/ibank/logonAction.action' do
  redirect '/ibank/viewAccountPortfolio.action', 302
end

get '/ibank/viewAccountPortfolio.action' do
  <<-END
    <h1>My Accounts</h1>
    <ul id="acctSummaryList" class="list">
      <h2 class="ico ico-visa"><a href="javascript:viewAccountDetails('accountDetails.action?index=0')">Savings Account</a></h2>
      <h2 class="ico ico-visa"><a href="javascript:viewAccountDetails('accountDetails.action?index=1')">Credit Card</a></h2>
    </ul>
  END
end

get '/ibank/accountDetails.action' do
  index = params[:index]
  <<-END
    <a class="goto-more" href="viewStmt_processSelectedAcct.action?newPage=1&amp;index=#{index}">View eStatements</a>
  END
end

get '/ibank/viewStmt_processSelectedAcct.action' do
  <<-END
    <a href="viewStmt_processStatement.action?newPage=1&amp;index=0">29 February 2016&nbsp;</a>
  END
end

post '/ibank/viewStmt_processSelectedAcct.action' do
  <<-END
    <a href="viewStmt_processStatement.action?newPage=1&amp;index=0">29 February 2016&nbsp;</a>
    <a href="viewStmt_processStatement.action?newPage=1&amp;index=1">31 January 2016&nbsp;</a>
  END
end

get '/ibank/exportTransactions.action' do
  content_type :csv
  "a,b,c\n1,2,3"
end

get '/ibank/viewStmt_processStatement.action' do
  content_type :pdf
  "Pdf for #{params[:index]}"
end

post '/ibank/showTransactionHistory.action' do
  'meh'
end