module tagion.Base;
import tagion.utils.BSON : R_BSON=BSON, Document;
alias R_BSON!true GBSON;
import tagion.crypto.Hash;
import tagion.BSONType;
import std.string : format;
import std.stdio : writefln, writeln;

enum this_dot="this.";

import std.conv;
/**
   Return the position of first '.' in string and
 */
template find_dot(string str, size_t index=0) {
    static if ( index >= str.length ) {
        enum zero_index=0;
        alias zero_index find_dot;
    }
    else static if (str[index] == '.') {
        enum index_plus_one=index+1;
        static assert(index_plus_one < str.length, "Static name ends with a dot");
        alias index_plus_one find_dot;
    }
    else {
        alias find_dot!(str, index+1) find_dot;
    }
}

/**
   Template function for removing the "this." prefix
 */
template basename(alias K) {
    enum name=K.stringof;
    static if (
        (name.length > this_dot.length) &&
        (name[0..this_dot.length] == this_dot) ) {
        alias name[this_dot.length..$] basename;
    }
    else {
        enum dot_pos=find_dot!(name);
        static if ( dot_pos > 0 ) {
            enum suffix=name[dot_pos..$];
            alias suffix basename;
        }
        else {
            alias name basename;
        }
    }
}

unittest {
    enum name_another="another";
    struct Something {
        mixin("int "~name_another~";");
        void check() {
            assert(find_dot!(this.another.stringof) == this_dot.length);
            assert(basename!(this.another) == name_another);
        }
    }
    Something something;
    static assert(find_dot!((something.another).stringof) == something.stringof.length+1);
    static assert(basename!(something.another) == name_another);
    something.check();
}

template EnumText(string name, string[] list, bool first=true) {
    static if ( first ) {
        enum begin="enum "~name~"{";
        alias EnumText!(begin, list, false) EnumText;
    }
    else static if ( list.length > 0 ) {
        enum k=list[0];
        enum code=name~k~" = "~'"'~k~'"'~',';
        alias EnumText!(code, list[1..$], false) EnumText;
    }
    else {
        enum code=name~"}";
        alias code EnumText;
    }
}

unittest {
    enum list=["red", "green", "blue"];
//    pragma(msg, EnumText!("Colour", list));
    mixin(EnumText!("Colour", list));
    static assert(Colour.red == list[0]);
    static assert(Colour.green == list[1]);
    static assert(Colour.blue == list[2]);

}
enum ThreadState {
    KILL = 9,
    LIVE = 1
}

enum EventProperty {
	IS_STRONGLY_SEEING,
	IS_FAMOUS,
	IS_WITNESS
}

@safe
struct EventUpdateMessage {
    immutable uint bson_type_code=bsonType!(typeof(this));
    uint id;
	EventProperty property;
	bool value;

    this (const uint id, const EventProperty property, const bool value) {
        this.id = id;
        this.property = property;
        this.value = value;
    }

    this(immutable(ubyte)[] data) inout {
        auto doc=Document(data);
        this(doc);
    }

    this(Document doc) inout {
        foreach(i, ref m; this.tupleof) {
            alias typeof(m) type;
            writeln("Type for member: ", type.stringof);
            enum name=basename!(this.tupleof[i]);
            //CheckBSON!(cc, name, doc);
            if ( doc.hasElement(name) ) {
                static if(is(type == enum)) {
                    auto value = doc[name].get!uint;
                    if(value <= type.max) {
                        this.tupleof[i]=cast(type)value;
                    }
                    else {
                        throw new BsonCastException("The chosen enum element is out of range");
                    }
                }
                else {
                    writefln("Inserting value for : %s with the value: %s and doc type: %s", name, doc[name], doc[name].type);
                    this.tupleof[i]=doc[name].get!type;
                }
            }
        }
    }

    GBSON toBSON () const {
        auto bson = new GBSON();
        foreach(i, m; this.tupleof) {
            enum name = basename!(this.tupleof[i]);
            static if ( __traits(compiles, m.toBSON) ) {
                bson[name] = m.toBSON;
                //pragma(msg, format("Associated member type %s implements toBSON." , name));
            }

            bool include_member = true;

            static if ( __traits(compiles, m.length ) ) {
                include_member = m.length != 0;
                //pragma(msg, format("The member %s is an array type", name) );
            }

            enum member_is_enum = is(typeof (m) == enum );

            if( include_member ) {
                static if(member_is_enum) {
                    bson[name] = cast(uint)m;
                }
                else {
                    bson[name] = m;
                }

                //pragma(msg, format("Member %s included.", name) );
            }
        }
        return bson;
    }

    immutable(ubyte)[] serialize() const {
        return toBSON().serialize;
    }
}

unittest { // Serialize and unserialize EventCreateMessage

    auto seed_body=EventUpdateMessage(1, EventProperty.IS_FAMOUS, true);
    writefln("Event id: %s,  Event property: %s : %s  ,   bson_type_code: %s", seed_body.id, seed_body.property.stringof, seed_body.value, seed_body.bson_type_code);
    auto raw=seed_body.serialize;

    auto replicate_body=EventUpdateMessage(raw);

    // Raw and repicate shoud be the same
    assert(seed_body == replicate_body);
}

@safe
struct EventCreateMessage {
    uint id;
    uint mother_id;
	uint father_id;
	immutable(ubyte)[] payload;
    uint node_id;
    bool witness;

    this(const(uint) id,
	immutable(ubyte)[] payload,
    const(uint) node_id,
	const(uint) mother_id,
	const(uint) father_id,
    const(bool) witness
	) inout {
        this.id = id;
        this.mother_id = mother_id;
		this.father_id = father_id;
		this.payload = payload;
        this.node_id = node_id;
        this.witness = witness;
    }

    this(immutable(ubyte)[] data) inout {
        auto doc=Document(data);
        this(doc);
    }

    this(Document doc) inout {
        foreach(i, ref m; this.tupleof) {
            alias typeof(m) type;
            writeln("Type for member: ", type.stringof);
            enum name=basename!(this.tupleof[i]);
            if ( doc.hasElement(name) ) {
                static if(is(type == enum)) {
                    auto value = doc[name].get!uint;
                    if(value <= type.max) {
                        this.tupleof[i]=cast(type)value;
                    }
                    else {
                        throw new BsonCastException("The chosen enum element is out of range");
                    }
                }
                else {
                    writefln("Inserting value for : %s with the value: %s and doc type: %s", name, doc[name], doc[name].type);
                    this.tupleof[i]=doc[name].get!type;
                }
            }
        }
    }

    GBSON toBSON () const {
        auto bson = new GBSON();
        foreach(i, m; this.tupleof) {
            enum name = basename!(this.tupleof[i]);
            static if ( __traits(compiles, m.toBSON) ) {
                bson[name] = m.toBSON;
                //pragma(msg, format("Associated member type %s implements toBSON." , name));
            }

            bool include_member = true;

            static if ( __traits(compiles, m.length ) ) {
                include_member = m.length != 0;
                //pragma(msg, format("The member %s is an array type", name) );
            }

            enum member_is_enum = is(typeof (m) == enum );

            if( include_member ) {
                static if(member_is_enum) {
                    bson[name] = cast(uint)m;
                }
                else {
                    bson[name] = m;
                }

                //pragma(msg, format("Member %s included.", name) );
            }
        }
        return bson;
    }

    immutable(ubyte)[] serialize() const {
        return toBSON().serialize;
    }
}

unittest {
    auto payload = cast(immutable(ubyte)[])"Test payload";
    auto seed_body = EventCreateMessage(1, payload, 2, 3, 5, false);
    auto raw = seed_body.serialize;

    auto replicate_body = EventCreateMessage(raw);
    assert(replicate_body == seed_body);

}

@safe
immutable(Hash) hfuncSHA256(immutable(ubyte)[] data) {
    import tagion.crypto.SHA256;
    return SHA256(data);
}

@safe
class BsonCastException : Exception {
    this( immutable(char)[] msg, string file = __FILE__, size_t line = __LINE__ ) {
        super( msg, file, line );
    }
}