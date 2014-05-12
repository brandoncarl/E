
### Installation
```
$ npm install eplus
```

### Quick Start

```

var E = require("eplus")

// Set up some errors
E.registerError("Authentication Error");
E.registerError("Database Error");
E.registerError("Mail Error");


// Add some transports: they must have a "log" function
E.addTransport({
  name : "console",
  log  : function(err, data) {
    console.log(err.stack);
  }
});


// And how to use it!

if (/* errors during authentication /*)
  err = new E.Authentication("Bad authentication", { mod : "Auth", fxn : "login", user : email });

// Test error types (for instance, when choosing what to show to the user)
if (err.is("Authentication Error"))
  // Send "That email and password aren't recognized"
else
  // Send "An unknown error occurred. Please contact us for help."


```