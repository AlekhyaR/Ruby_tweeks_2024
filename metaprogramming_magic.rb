Dynamic Class calling in Ruby on Rails

Introduction:

Hello there! Today, let’s explore a cool trick in Ruby on Rails called metaprogramming. Imagine you’re building a website, and you want to seamlessly handle payments
with both Stripe and PayPal. No worries, it’s like having a super-friendly helper to make it all smooth!

Understanding Metaprogramming:

Metaprogramming in Ruby revolves around manipulating the behaviour of programs, classes, and objects at runtime. It empowers developers to write more flexible 
and efficient code by creating abstractions and reducing redundancy.

Setting the Scene:

Picture this — you’re at an online store, ready to buy something. Now, instead of only using one way to pay, you can choose between Stripe and PayPal, 
two popular payment methods. Metaprogramming helps us keep things flexible and straightforward!

You have different classes representing payment gateways in a Ruby on Rails application. Instead of hardcoding the logic for each payment gateway, 
you want to dynamically call the appropriate class based on a value, such as the selected payment method.

Step 1: Define Base Class

First, let’s create a base class, PaymentGateway, with a generic method process_payment. This class will serve as the blueprint for specific payment 
gateway implementations.

class PaymentGateway
  def process_payment(amount)
    raise NotImplementedError, "Subclasses must implement the process_payment method"
  end
end
  
Step 2: Implement Specific Payment Gateways

Now, let’s create two classes, StripeGateway and PayalGateway, that inherit from the PaymentGateway class and 
implement the process_payment method according to their respective logic.

class StripeGateway < PaymentGateway
  def process_payment(amount)
    puts "Processing payment of ₹#{amount} via Stripe"
    # Add Stripe-specific logic here
  end
end

class PayPalGateway < PaymentGateway
  def process_payment(amount)
    puts "Processing payment of ₹#{amount} via PayPal"
    # Add PayPal-specific logic here
  end
end
  
Step 3: Metaprogramming Magic

Now, let’s implement a method that dynamically instantiates the appropriate payment gateway class based on a given payment method.

class PaymentProcessor
  def self.process_payment(payment_method, amount)
    gateway_class = "#{payment_method.camelize}Gateway"

    unless PaymentGateway.const_defined?(gateway_class)
      raise ArgumentError, "Invalid payment method: #{payment_method}"
    end

    gateway_instance = PaymentGateway.const_get(gateway_class).new
    gateway_instance.process_payment(amount)
  end
end

Step 4: Putting It All Together

Now, you can use the PaymentProcessor to dynamically call the appropriate payment gateway class based on the payment method.

PaymentProcessor.process_payment("stripe", 100)
# Output: Processing payment of ₹100 via Stripe

PaymentProcessor.process_payment("pay_pal", 50)
# Output: Processing payment of ₹50 via PayPal
  
Conclusion:

There you have it! Metaprogramming in Ruby on Rails makes handling payments with Stripe and PayPal as easy as choosing your favourite snack. 
Give it a try and enjoy the simplicity in your coding journey!
