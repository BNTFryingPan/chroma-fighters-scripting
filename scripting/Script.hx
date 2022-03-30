package scripting;

#if flixel
import flixel.FlxG;
import flixel.system.debug.log.LogStyle;
#end
import haxe.ds.GenericStack;
import scripting.Op.Operation;
import scripting.Op.UnOperation;

/*enum StackEntryType {
   NUMBER;
   STRING;
   NULL;
   }

   class StackEntry<T> {
   public final value:T;
   public final type:StackEntryType;

   private function new(type:StackEntryType, value:T) {
      this.value = value;
      this.type = type;
   }

   public function isString():Bool {
      return this.type == STRING;
   }

   public function isNumber():Bool {
      return this.type == NUMBER;
   }

   public function castTo(targetType:StackEntryType):StackEntry<Dynamic> {
      if (targetType == this.type)
         return this;

      if (targetType == STRING)
         return new StackEntry<String>(STRING, Std.string(this.value));

      if (targetType == NUMBER)
         return new StackEntry<Float>(NUMBER, Std.parseFloat(Std.string(this.value)));

      return new StackEntry<Dynamic>(NULL, null);
   }

   public static function get(value:Dynamic):StackEntry<Dynamic> {
      if (value is String) {
         return new StackEntry<String>(STRING, value);
      }
      if (value is Float || value is Int) {
         return new StackEntry<Float>(NUMBER, value);
      }

      return new StackEntry<Dynamic>(NULL, null);
   }
}*/
#if js
@:expose
#end
class Script {
   public var error:Null<String> = null;

   public static var DEBUG_TOKENS:Bool = true;
   public static var DEBUG_NODE_TREE:Bool = false;
   public static var DEBUG_BYTECODE:Bool = true;
   public static var DEBUG_RUNTIME:Bool = false;

   // private var isParsed:Fuse = new Fuse();
   private var isCompiled:Fuse = new Fuse();
   var contents:String;
   var tokens:Array<Script> = [];
   var node:Script;
   var actions:Array<Script>;

   public var isRunning:Bool = false;
   public var isPaused:Bool = false;

   var pausedFor:Int = 0;
   var pos:Int = 0;

   var stack:GenericStack<Dynamic>;
   var vars:Dynamic;

   // var discarded:Dynamic = null;

   function new(script:String) {
      this.contents = script;
   }

   /*
      public function parse() {
         if (this.isParsed.isBlown())
            return;
         this.isParsed.blow();

         this.tokens = Parser.parse(this.contents);
   }*/
   public function compile() {
      if (this.isCompiled.isBlown()) // already parsed
         return;
      this.isCompiled().blow();
      this.tokens = Parser.parse(this.contents);
      if (Script.DEBUG_TOKENS)
         trace('parsed: ' + tokens.map(t -> t.debugPrint()).join(''));
      this.node = Builder.build(this.tokens);
      if (Script.DEBUG_NODE_TREE)
         trace(this.node.debugPrint());
      this.actions = Compiler.compile(this.node);
      if (Script.DEBUG_BYTE_CODE)
         trace('"bytecode":\n${actions.map(a -> a.debugPrint()).join('\n')}');
   }

   public function exec(vars:Null<Dynamic>):Dynamic {
      // if (forceRestart || !this.isRunning) {
      stack = new GenericStack<Dynamic>();
      pos = 0;
      if (vars != null) {
         this.vars = vars;
      }
      // }
      // if (this.isPaused) {
      //   this.pausedFor--;
      //   if (this.pausedFor > 0) return null;
      // }
      // this.isRunning = true;
      // this.isPaused = false;
      while (pos < this.actions.length) {
         var action = this.actions[pos++];
         this.executeAction(action);
         if (Script.DEBUG_RUNTIME)
            trace('<exec> ${action.debugPrint()} (${stack.first()}, $pos)');
      }
      // for (act in this.actions) {
      //   this.executeAction(act);
      // }
      // if (this.isPaused)
      //   return null;
      // this.isRunning = false;
      return stack.pop();
   }

   function executeAction(action:Action) {
      inline function error(text:String) {
         return '${text} at position ${action.getPos()}';
      }

      switch (action) {
         // case APause(p, frames):
         // isPaused = true;
         // pausedFor = frames;
         case ANumber(p, value):
            stack.add(value);
         case AString(p, value):
            stack.add(value);
         case AIdentifier(p, name):
            {
               if (!Reflect.hasField(vars, name))
                  throw error('variable $name does not exist when referenced');

               var val = Reflect.field(vars, name);
               stack.add(val);
            }
         case AOperation(p, op):
            {
               var b = stack.pop();
               var a = stack.pop();
               if (op == Operation.EQUALS) {
                  trace('checking if ${a} == ${b} (${a == b}');
                  a = (a == b);
               } else if (op == Operation.NOT_EQUALS) {
                  trace('checking if ${a} != ${b} (${a != b}');
                  a = (a != b);
               } else if (b is String || a is String) {
                  var fin:String;
                  switch (op) {
                     case Operation.ADD:
                        fin = Std.string(a) + Std.string(b);
                     /*case Operation.MULTIPLY:
                        if (b.isNumber() || a.isNumber()) {
                           fin = Std.string(a.value * b.value);
                     } else throw error('cannot multiply a string by a string');*/
                     default: throw error('cant apply ${op.toString()} to ${a} and ${b}');
                  }
                  stack.add(fin);
               } else {
                  switch (op) {
                     case Operation.ADD: a += b;
                     case Operation.SUBTRACT: a -= b;
                     case Operation.MULTIPLY: a *= b;
                     case Operation.DIVIDE: a /= b;
                     case Operation.MOD: a %= b;
                     case Operation.DIVIDE_INT: a = Std.int(a / b);
                     case Operation.LESS_THAN: a = (a < b);
                     case Operation.LESS_THAN_OR_EQUALS: a = (a <= b);
                     case Operation.GREATER_THAN: a = (a > b);
                     case Operation.GREATER_THAN_OR_EQUALS: a = (a >= b);
                     case Operation.BIT_SHIFT_LEFT: a <<= b;
                     case Operation.BIT_SHIFT_RIGHT: a >>= b;
                     case Operation.BIT_AND: a &= b;
                     case Operation.BIT_OR: a |= b;
                     case Operation.BIT_XOR: a ^= b;
                     default: throw error('cant apply ${op.toString()}');
                  }
                  stack.add(a);
               }
            }
         case AUnOperation(p, op):
            {
               var v = stack.pop();
               if (v is String)
                  throw error('cannot negate strings');
               switch (op) {
                  case UnOperation.NOT: v = v != 0 ? 0 : 1;
                  case UnOperation.NEGATE: v = -v;
               }
               stack.add(v);
            }
         case ACall(p, name, argCount):
            {
               var args = new Array<Dynamic>();
               args.resize(argCount);
               var i = argCount;
               while (--i >= 0)
                  args[i] = stack.pop();

               stack.add(ScriptAPI.callScriptFunction(name, ...args));
            }
         case AReturn(p):
            pos = actions.length;
         case ADiscard(p):
            stack.pop();
         case AJump(p, to):
            pos = to;
         case AJumpUnless(p, to):
            if (!isTruthy(stack.pop())) {
               pos = to;
            }
         case AJumpIf(p, to):
            if (isTruthy(stack.pop())) {
               pos = to;
            }
         case AAnd(p, to):
            if (isTruthy(stack.first()))
               stack.pop();
            else
               pos = to;
         case AOr(p, to):
            if (isTruthy(stack.first()))
               pos = to;
            else
               stack.pop();
         case ASet(p, name):
            Reflect.setField(vars, name, stack.pop());
      }
   }

   static function isTruthy(value:Dynamic):Bool {
      trace('checking truthiness of `${Std.string(value)}`');
      if (value is Bool) {
         return value;
      }
      if (value is Int || value is Float) {
         if (value == 0)
            return false;
         if (value == Math.NaN)
            return false;
         return true;
      }
      if (value is String) {
         if (value == '')
            return false;
         return true;
      }
      if (value == null) {
         return false;
      }
      return false;
   }

   public static function eval(code:String):String {
      try {
         var pg = new Script(code);
         pg.compile();
         var v = pg.exec({pi: Math.PI});
         return Std.string(v);
      }
      catch (x:Dynamic) {
         #if FLX_DEBUG
         FlxG.log.advanced(x, errorLogStyle, false);
         #end
         return null;
      }
   }

   public static final errorLogStyle:LogStyle = new LogStyle("[SCRIPT ERROR]", "ff00ff", 12, false, false, false, "flixel/sounds/beep", false);
}
