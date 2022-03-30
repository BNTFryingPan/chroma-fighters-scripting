package scripting;

enum abstract UnOperation(Int) {
   var NOT;
   var NEGATE;
}

enum abstract Operation(Int) {
   // math
   var MULTIPLY = 0x01; // *
   var DIVIDE = 0x02; // /
   var MOD = 0x03; // % or mod
   var DIVIDE_INT = 0x04; // div
   var ADD = 0x10; // +
   var SUBTRACT = 0x11; // -
   // bitwise
   var BIT_SHIFT_LEFT = 0x20; // <<
   var BIT_SHIFT_RIGHT = 0x21; // >>
   var BIT_AND = 0x30; // &
   var BIT_OR = 0x31; // |
   var BIT_XOR = 0x32; // ^
   // comparison
   var EQUALS = 0x40; // ==
   var NOT_EQUALS = 0x41; // !=
   var LESS_THAN = 0x42; // <
   var LESS_THAN_OR_EQUALS = 0x43; // <=
   var GREATER_THAN = 0x44; // >
   var GREATER_THAN_OR_EQUALS = 0x45; // >=
   // bool
   var AND = 0x50;
   var OR = 0x60;
   // misc
   var MAXP = 0x70;

   public inline function getPriority():Int {
      return this >> 4;
   }

   public function toString():String {
      return 'operator 0x${StringTools.hex(this, 2)}';
   }
}
