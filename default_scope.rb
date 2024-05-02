Ever wondered if you could use 'default_scope' apart from selects and inserts, but for updates and deletes too?

🖼 Imagine this:
You're working on a ticket management app, 
carefully sorting data based on organization_id.
 
Now, here's the catch: you want every query 
(select, insert, update, or delete) 
to smoothly match the current organization, 
keeping your data neat and organized.

class Ticket < ApplicationRecord
   default_scope -> { where(organization_id: Current.organization_id) }
end

Now, when you run 
Ticket.all or Ticket.new : 
→ It'll always have organization_id set to Current.organization_id.

🤔 But, what if you try:
↳  Ticket.update_all(status: 'todo')
 Updates all Ticket statuses to 'todo'.

 ↳ Ticket.destroy_all
 Deletes all Tickets from our database. 
 
😔 Oh, we don't want that.

We can achieve updating and deleting records 
by adding where query:
 - Ticket.where(organization_id: Current.organization_id).update_all(status: 'todo')
 - Ticket.where(organization_id: Current.organization_id).destroy_all

😮 But doesn't this seem like extra work? 
Having to write 
where(organization_id: Current.organization_id)
every time might be a bit much, right?
 
Here is the magic: "all_queries: 'true'"

→ Add it with the scope: 
class Ticket < ApplicationRecord
   default_scope -> { where(organization_id: Current.organization_id) }, all_queries: 'true'
end

Now, you don't need to do extra conditions and also you have to maintain your data 
aligned with the organization.

#code-reference

default_scope without all_queries
---------------------------------
class Ticket < ApplicationRecord
  default_scope -> {
    where (organization_id: Current.organization_id)
  } 
end
# Considering Current.organization_id is 1 Ticket.update_all(status: 'todo')
# UPDATE "tickets" SET "status" = 'todo';
Ticket.destroy_all
# DELETE FROM "tickets";

default_scope with all_queries
------------------------------
class Ticket < ApplicationRecord
  default_scope -> {
    where(organization_id: Current.organization_id)
  },
  all_queries: 'true'
end

#Considering Current.organization_id is 1
Ticket.update_all(status: 'todo')
# UPDATE "tickets" SET "status" = 'todo' where organization_id= 1;
Ticket.destroy_all
# DELETE FROM "tickets" where organization_id= 1;
