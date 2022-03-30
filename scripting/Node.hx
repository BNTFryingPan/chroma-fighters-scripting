package scripting;

import scripting.Op;

@:using(Node.NodeTools)
enum Node {
   NNumber(p:Pos, f:Float);
   NIdentifier(p:Pos, s:String);
   NUnOperator(p:Pos, op:UnOperation, q:Node);
   NOperator(p:Pos, op:Operation, a:Node, b:Node);
   NCall(p:Pos, name:String, args:Array<Dynamic>);
   NString(p:Pos, v:String);
   NBlock(p:Pos, nodes:Array<Node>);
   NReturn(p:Pos, node:Node);
   NDiscard(p:Pos, node:Node);
   NConditional(p:Pos, condition:Node, result:Node, elseResult:Null<Node>);
   NSet(p:Pos, node:Node, value:Node);
   NWhile(p:Pos, condition:Node, expr:Node);
   NWhileDo(p:Pos, condition:Node, expr:Node);
   NFor(p:Pos, init:Node, condition:Node, post:Node, node:Node);
   NBreak(p:Pos);
   NContinue(p:Pos);
}

class NodeTools {
   public static function getPos(a:Node):Pos {
      return a.getParameters()[0];
   }

   private static function convertParamToString(param:Dynamic):String {
      if (param is Array) {
         return '[' + param.map(p -> convertParamToString(p)).join(', ') + ']';
      }
      if (param is Node) {
         return NodeTools.debugPrint(param);
      }
      if (param is Int || param is Float || param is Bool) {
         return Std.string(param);
      }
      if (param is String) {
         '"${Std.string(param)}"';
      }
      return '{"type": "${Type.typeof(param)}", "value": "${Std.string(param)}"}';
   }

   public static function debugPrint(a:Node):String {
      // gets the syntax tree of this node
      var params = a.getParameters().map(p -> convertParamToString(p));
      return '{"nodeType": "${a.getName()}", "params": [${params.join(', ')}]}';
      // var params:Array<String> = a.getParameters().map(p -> Std.string(p));
      // var formatted = '[${a.getPos()}] ${a.getName()} {${params.join(', ')}}';
      // trace(formatted);
      // return formatted;
   }
}
