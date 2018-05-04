module tagion.Keywords;

private import tagion.Base : EnumText;

// Keyword list for the BSON packages
enum _keywords = [
    "pubkey",       // Pubkey
    "sig",        // signature of the block
    "altitude",   // altitude
    "tidewave",
    "wavefront",  // Wave front is the list of events hashs
    "ebody",      // Event body
//        "events",     // List of event
    "type",       // Package type
    "block"     // block
    ];

// Generated the Keywords and enum string list
mixin(EnumText!("Keywords", _keywords));
