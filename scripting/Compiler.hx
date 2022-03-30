package scripting;

/**
   the compiler takes a root node that contains sub nodes and compiles it into a list of actions that can be executed
**/
class Compiler {
   static var actions:Array<Action>;

   static inline function add(a:Action):Void {
      actions.push(a);
   }

   static function expr(node:Node):Void {
      switch (node) {
         case NNumber(p, f):
            add(ANumber(p, f));
         case NIdentifier(p, s):
            add(AIdentifier(p, s));
         case NUnOperator(p, op, q):
            expr(q);
            add(AUnOperation(p, op));
         case NOperator(p, op, a, b):
            expr(a);
            expr(b);
            add(AOperation(p, op));
         case NString(p, v):
            add(AString(p, v));
         case NCall(p, name, args):
            for (arg in args) {
               expr(arg);
            }
            add(ACall(p, name, args.length));
         case NBlock(p, nodes):
            for (blockNode in nodes)
               expr(blockNode);
         case NReturn(p, ret):
            expr(ret);
            add(AReturn(p));
         case NDiscard(p, ret):
            expr(ret);
            add(ADiscard(p));
         case NConditional(p, condition, result, elseResult):
            expr(condition);
            var jump1index = actions.length;
            expr(result);
            var jump2index = 0;
            if (elseResult != null) {
               expr(elseResult);
               jump2index = actions.length;
            }
            actions.insert(jump1index, AJumpUnless(p, actions.length));
            if (elseResult != null) {
               actions.insert(jump2index - 1, AJump(p, actions.length + 1));
            }
         case NSet(p, node, value):
            {
               expr(value);
               switch (node) {
                  case NIdentifier(p, name): {
                     add(ASet(p, node.getParameters()[1]));
                  }
                  default: throw 'Expression is not settable at $p';
               }
            }
         case NWhile(p, condition, expression):
            {
               // label1: condition; jump_unless label2
               var cont_pos = actions.length;
               expr(condition);
               add(AJumpUnless(p, 0));
               // <loop> jump label1
               var start_pos = actions.length;
               expr(expression);
               add(AJump(p, cont_pos));
               // label2: break
               var break_pos = actions.length;
               actions[start_pos - 1] = AJumpUnless(p, break_pos);
               patch(start_pos, break_pos, break_pos, cont_pos);
            }
         case NWhileDo(p, condition, expression):
            {
               // label1: loop
               var start_pos = actions.length;
               expr(expression);
               // label2: condition; jumpif label1
               var cont_pos = actions.length;
               expr(condition);
               add(AJumpIf(p, start_pos));
               // label3: break
               var break_pos = actions.length;
               patch(start_pos, break_pos, break_pos, cont_pos);
            }
         case NFor(p, init, condition, post, node):
            {
               expr(init);
               // label1: condition jumpunless label3
               var loop_pos = actions.length;
               expr(condition);
               add(AJumpUnless(p, 0));
               // loop
               var start_pos = actions.length;
               expr(node);
               // label2: cont, post, jump label1
               var cont_pos = actions.length;
               expr(post);
               add(AJump(p, loop_pos));
               // label3: break
               var break_pos = actions.length;
               actions[start_pos - 1] = AJumpUnless(p, break_pos);
               patch(start_pos, break_pos, break_pos, cont_pos);
            }
         case NBreak(p):
            add(AJump(p, -10));
         case NContinue(p):
            add(AJump(p, -11));
      }
   }

   private static function patch(start, end, _break, _continue) {
      var i = start;
      while (i < end) {
         switch (actions[i]) {
            case AJump(p, to):
               {
                  if (to == -10) {
                     actions[i] = AJump(p, _break);
                  } else if (to == -11) {
                     actions[i] = AJump(p, _continue);
                  }
               }
               default:
         }
         i++;
      }
   }

   public static function compile(node:Node):Array<Action> {
      actions = [];
      expr(node);
      return actions;
   }
}
