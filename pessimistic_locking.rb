Pessimistic Locking

🤔 What is Pessimistic Locking?
→ It is a concurrency control mechanism.
→ Ensure data consistency.
→ It follows a "lock first, edit later" approach.
→ It’s a row-level locking of SQL.

🤔 Why should we care?
→ Preventing Overwriting: One user can edit at a time.
→ For complex transactions: Like Financial, Inventory, reservation, etc.

💡 When do we use Locking?

Imagine a scenario:
1. We have a travel booking system with limited seats (10 left). 
2. Two travelers, Alice and Bob, want the same flight. 

❌ Without Locking,
here's what could go wrong:

1. Alice and Bob see 10 seats.
2. They try booking simultaneously.

This leaves the data inconsistent:
1. Allows overbooking due to race conditions.
2. Exceeds capacity (1 seat)
3. Now shows 9 seats available.

🎩 Let's put on our Ruby on Rails hat,
 and start implementing Pessimistic Locking.

✅ Call lock method on active record object 
(OR)
✅ Write code with_lock block

👉 Breakdown of steps:
1. Alice locks a seat.
2. Bob sees it's locked (unavailable).
3. Alice books, reduce seats, and releases the lock.
4. Bob sees updated availability (9 seats).

🎉 Voila! 
Now your Rails app can handle concurrent edits 
like a champ, thanks to pessimistic locking!

#code-reference

class FlightBookingService
  def book_seat(flight_id, user_id, seat_number) 
    Flight.find_by(id: flight_id).with_lock do |flight| 
      if flight.available_seats > 0
        # Lock acquired, guaranteed accurate seat count 
        seat = flight.seats.find_by(seat_number: seat_number) 
        if seat.present? && !seat.booked?
          seat.update! (booked: true, booked_by: user_id)
          flight.update! (available_seats: flight.available_seats - 1) 
          return true 
          # Booking successful
        else
          # Handle scenario where seat is unavailable return false 
          # Booking failed
        end
      else
        # Handle scenario where no seats are available return false 
        # Booking failed
      end
    end
  end
end

🤝 Over to You: 
→ Lock! vs. with_lock? What's your pick?
→What factors matter most (granularity, deadlocks, performance)?
  Pick your lock:
- Rare conflicts? Optimistic locking for speed.
- Critical data? Pessimistic locking for safety.
- Complex transactions? Pessimistic locking avoids mid-process conflicts.
