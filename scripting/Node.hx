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
   NReturn(p:Pos, node:Null<Node>);
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
   
   private static function param(name:String, value:String) {
      return '"$name": $value';
   }

   private static function asJson(a:Node):String {
      var type = a.getName().substring(1);
      var params:Array<String> = ['"pos": ${a.getPos()}'];
      switch (a) {
         case NNumber(_, value): params.push(param("value", value));
         case NIdentifier(_, name): params.push(param("name", name));
         case NString(_, value): params.push(param("text", value));
         case NUnOperator(_, op, q):
            params.push(param('op', Std.string(op)));
            params.push(param('value', q.asJson()));
         case NOperator(_, op, a, b):
            params.push(param('a', a.asJson()));
            params.push(param('op', Std.string(op)));
            params.push(param('b', b.asJson()));
         case NCall(_, name, args):
            params.push(param('name', name));
            params.push(params('arguments', '[${nodes.map(n -> n.asJson()).join(",")}]'));
         case NBlock(_, nodes): params.push(param('nodes', '[${nodes.map(n -> n.asJson()).join(",")}]'));
         case NReturn(_, node): params.push(param('value', node.asJson()));
         case NDiscard(_, node): params.push(param('value', node.asJson()));
         case NConditional(_, cond, result, elseResult):
            params.push(param('condition', cond.asJson()));
            params.push(param('true_node', result.asJson()));
            if (elseResult != null) params.push(param('false_node', elseResult.asJson()));
         case NSet(_, node, value):
            params.push(param('target', node.asJson()));
            params.push(param('value', value.asJson()));
         case NWhile(_, cond, node):
            params.push(param('condition', cond.asJson()));
            params.push(param('body', node.asJson()));
         case NWhileDo(_, cond, node):
            params.push(param('condition', cond.asJson()));
            params.push(param('body', node.asJson()));
         case NFor(_, init, cond, post, node):
            params.push(param('init', init.asJson()));
            params.push(param('condition', cond.asJson()));
            params.push(param('post', post.asJson()));
            params.push(param('body', node.asJson()));
         case NBreak(_):
         case NContinue(_):
         default:
            //var nodeParams = 
      }
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
