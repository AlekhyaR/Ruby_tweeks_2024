The aim of the research is the question we have been discussing on the project. I’m fully confident that Ruby on Rails developers face that case pretty often, but don’t attach importance to it. I suppose my article will be useful for both beginners and experienced RoR engineers. Enjoy!

We have a set of SQL queries. One of them may cause a DB error. There are 3 ways to send this set of queries to PostgreSQL: ActiveRecord::Base.connection.execute method, BEGIN & COMMIT in SQL statement, ActiveRecord::Base.transaction method

The question is, how will these approaches work?

Let’s investigate our problem using the following set of queries:

UPDATE employees SET last_name = '' where id = 1; 
UPDATE employees SET last_name = sss where id = 1; # this will cause a mistake
We can use execute method
ActiveRecord::Base.connection.execute(
  <<-SQL
    UPDATE employees SET last_name = '' where id = 1;
    UPDATE employees SET last_name = sss where id = 1;
  SQL
)

2. We can use BEGIN & COMMIT

ActiveRecord::Base.connection.execute(
  <<-SQL
    BEGIN;
      UPDATE employees SET last_name = '' where id = 1;
      UPDATE employees SET last_name = sss where id = 1;
    COMMIT;
  SQL
)

3. We can use transaction method

ActiveRecord::Base.transaction do
  ActiveRecord::Base.connection.execute(
    <<-SQL
      UPDATE employees SET last_name = '' where id = 1;
      UPDATE employees SET last_name = sss where id = 1;
    SQL
  )
end

Can you answer the main question right away? Let’s dig deeper and check the performance of each approach. 
By the way, my current Ruby version is 3.1.4, Rails version is 6.1.7.5.

Execute method
As you can see in below code

def execute(sql, name = nil)
  if preventing_writes? && write_query?(sql)
    raise ActiveRecord::ReadOnlyError, "Write query attempted while in readonly mode: #{sql}"
  end

  materialize_transactions
  mark_transaction_written_if_write(sql)

  log(sql, name) do
    ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
      @connection.async_exec(sql)
    end
  end
end

execute method does not wrap the statements into a transaction, it sends the set of queries to pg gem async_exec method as it is.
https://github.com/rails/rails/blob/v6.1.7.5/activerecord/lib/active_record/connection_adapters/postgresql/database_statements.rb#L39 

pry(#<ActiveRecord::ConnectionAdapters::PostgreSQLAdapter>)> sql
UPDATE employees SET last_name = '' where id = 1; \n UPDATE employees SET last_name = sss where id= 1;\n"
the value of sql variable that is sent to async_exec method

static VALUE
pgconn_async_exec(int argc, VALUE *argv, VALUE self)
{
VALUE rb_pgresult = Qnil;
paconn discard results( self ):
pgconn_send_query( argc, argv, self );
rb_pgresult = pgconn_async_get_last_result( self);
if (rb_block_given_p() ) {
}
return rb_ensure (rb_yield, rb_pgresult, pg_result_clear, rb_pgresult );
return rb_pgresult;
The next step is: pg gem sends the set of queries to PostgreSQL.

But the main point is that the changes that have been updated in the first
Let’s check PostegreSQL logs. The main question is: has our set of statements been wrapped into a transaction? 
As shown on the screen below, PostgreSQL got just 2 statements.

UPDATE employees SET last_name = '' where id = 1;
UPDATE employees SET last_name = sss where id= 1
ERROR: column "sss" does not exist at character 101 2023-09-20 17:15:46.630 MSK [36517] STATEMENT: UPDATE employees SET last_name = '' where id= 1;
UPDATE employees SET last_name = sss where id= 1

But the main point is that the changes that have been updated in the first statement haven’t been applied. That seems strange, isn’t it? We have 2 statements, 
the first one is correct, the second causes an error. We do not have a transaction, however, no changes have been applied. Why did it happen?

The answer is in the PostgreSQL documentation:
PostgreSQL actually treats every SQL statement as being executed within a transaction. If you do not issue a BEGIN command, then each individual statement has an implicit BEGIN and (if successful) COMMIT wrapped around it. A group of statements surrounded by BEGIN and COMMIT is sometimes called a transaction block.
https://www.postgresql.org/docs/current/tutorial-transactions.html

All in all, the execute method leads to the following result:
1. execute method won’t wrap set of statements into a transaction
2.changes won’t be applied because PostgreSQL has an implicit BEGIN and COMMIT wrapped around every SQL statement

BEGIN & COMMIT
After adding BEGIN and COMMIT into the SQL statement, we’ll get the same error:

[67] pry(main)> ActiveRecord::Base.connection.execute( <<-SOLL
)
SQL
BEGIN;
UPDATE employees SET last_name = where id= 1; UPDATE employees SET last_name = sss where id= 1; COMMIT;
2023-11-13 14:24:35.487060 D [90376:120900 (pry):57] (20.4ms) ActiveRecord -- { sql => " BEGIN;\n UPDATE employees SET last_name = where id id= 1; \n UPDATE employees SET last_name = s ss where id= 1;\n COMMIT;\n", :allocations => 1267, :cached => nil } ActiveRecord::StatementInvalid: PG::UndefinedColumn: ERROR: column "sss" does not exist LINE 3: UPDATE employees SET last_name = sss where id=...
entation/pg/patches/connection.rb:20:in `exec'
from /Users/user/.rvm/gems/ruby-3.1.4/gems/opentelemetry-instrumentation-pg-0.25.2/lib/opentelemetry/instrum column "sss" does not exist UPDATE employees SET last_name = sss where id=...
Caused by PG:: UndefinedColumn: ERROR:
LINE 3: Update employees SET last_name = sss where id = ...

Seems like it works absolutely like the previous approach. Let’s try to send any other request to DB using this connection:
[70] pry(main)> Employee.last
ActiveRecord::Statement Invalid: PG:: InFailedSqlTransaction: ERROR: current transaction is aborted, commands ignored until end of transaction block

Due to implicit BEGIN and COMMIT in PostgreSQL, no expressions after an error in the set of queries will be applied — neither COMMIT nor ROLLBACK, 
which has been passed at the end of the statement. In this way, a transaction will be opened but not closed. That causes further errors.

As a result, the BEGIN & COMMIT leads to the following outcome:
You need to handle statement errors to avoid the error of the uncompleted transaction block

transaction method

The ActiveRecord::Base.transaction provides really useful functionality to work with transactions. I’ll consider in detail the method’s features in my next 
article. Speaking of our current research, it provides additional queries which are sent to PostgreSQL:

# Begins a transaction.
def begin_db_transaction
execute("BEGIN", "TRANSACTION")
end
def begin_isolated_db_transaction(isolation)
begin_db_transaction
execute "SET TRANSACTION ISOLATION LEVEL #{transaction_isolation_levels.fetch(isolation)}"
end
# Commits a transaction.
def commit_db_transaction
execute("COMMIT", "TRANSACTION")
end
# Aborts a transaction.
def exec_rollback_db_transaction
execute("ROLLBACK", "TRANSACTION")
end

When we send statements inside ActiveRecord::Base.transaction block, we see the following result in console:

(pry):32] (2.422ms) ActiveRecord allocations >504, :cached => nil }
TRANSACTION
sql => "
(pry):32] (5.163ms) ActiveRecord { ET last_name = '' where id = 1;\n UPDATE employees SET last_name = sss where id= 1;\n",
: cached = nil }
(pry):31] (0.536ms) ActiveRecord :allocations => 504, cached➡ nil }
{ sql => "BEGIN", :
UPDATE employees S :allocations => 1405
TRANSACTION -- { :sql => "ROLLBACK"
ActiveRecord::Statement Invalid: PG:: Undefined Column: ERROR: column "sss" does not exist UPDATE employees SET last_name = sss where id= 1;
LINE 2:
from /Users/user/.rvm/gems/ruby-3.1.4/gems/opentelemetry-instrumentation-pg-0.25.2/lib/opentelemetry/instrumentati
on/pg/patches/connection.rb:20:in 'exec'
Caused by PG:: UndefinedColumn: ERROR: column "sss" does not exist
LINE 2:
UPDATE employees SET last_name = sss where id= 1;

The transaction method is pretty smart. It gets the DB answer and sends COMMIT or ROLLBACK back to PostgreSQL.

All in all, the transaction method leads to the following result:

1.Automatically sends BEGIN, COMMIT & ROLLBACK
2.Handle errors
3.Provides other helpful features
