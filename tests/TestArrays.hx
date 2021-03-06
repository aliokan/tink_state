package ;

import tink.state.*;

using tink.CoreApi;
using Lambda;
using StringTools;

@:asserts
class TestArrays {
  
  public function new() {}
  
  public function basics() {
    var a = new ObservableArray<Null<Int>>([for (i in 0...100) i]);
    var log = [];

    function clear()
      log = [];

    function getLog()
      return log.join(',').replace('undefined', '-').replace('null', '-');

    function report(name:String) return function (v:Null<Int>) log.push('$name:$v');

    a.observableLength.bind({ direct: true }, report('l'));
    
    a.observe(99).bind({ direct: true }, report('99'));

    asserts.assert(getLog() == 'l:100,99:99');
    clear();

    for (i in 0...10)
      a.pop();

    asserts.assert(getLog() == 'l:99,99:-,l:98,l:97,l:96,l:95,l:94,l:93,l:92,l:91,l:90');
    clear();

    for (i in 0...9)
      a.unshift(a.get(0)-1);    
    
    asserts.assert(getLog() == 'l:91,l:92,l:93,l:94,l:95,l:96,l:97,l:98,l:99');

    clear();
    a.unshift(a.get(0)-1);    
    asserts.assert(getLog() == '99:89,l:100');//It's a good question why exactly this happens out of order
    clear();
    for (i in 0...10)
      a.push(i);

    asserts.assert(getLog() == 'l:101,l:102,l:103,l:104,l:105,l:106,l:107,l:108,l:109,l:110');
    
    return asserts.done();
  }

  public function iteration() {
    var counter = 0,
        a = new ObservableArray();

    for (i in 0...10)
      a.push(i);

    for (i in a.observableValues.value)
      counter++;

    asserts.assert(counter == a.length);

    var evenCount = a.fold(function (v, count) return count + 1 - v.value % 2, 0);
    asserts.assert(evenCount == 5);

    var keysChanges = 0,
        valuesChanges = 0,
        iteratorChanges = 0;

    function sum(i:Iterator<Int>) {
      var ret = 0;
      for (i in i)
        ret += i;
      return ret;
    }

    Observable.auto(function () return sum(a.values()))
      .bind({ direct: true }, function () valuesChanges++);

    Observable.auto(function () return sum(a.keys()))
      .bind({ direct: true }, function () keysChanges++);

    Observable.auto(function () {
      var first = 0;
      for (v in a) {
        first += v.value;
        break;
      }
      return first;
    }).bind({ direct: true }, function () iteratorChanges++);

    asserts.assert(iteratorChanges * valuesChanges * keysChanges == 1);

    a.set(2, 4);

    asserts.assert(iteratorChanges == 1);
    asserts.assert(keysChanges == 1);
    asserts.assert(valuesChanges == 2);

    a.set(0, 1);

    asserts.assert(iteratorChanges == 2);
    asserts.assert(keysChanges == 1);
    asserts.assert(valuesChanges == 3);

    a.pop();

    asserts.assert(iteratorChanges == 3);
    asserts.assert(keysChanges == 2);
    asserts.assert(valuesChanges == 4);

    return asserts.done();
  }

  public function testIteratorResets() {
    var o = new ObservableArray<Int>(),
        name = new State('Alice'),
        log = [];

    var vals = o.observableValues;
    Observable.auto(function () {
        return name.value + ':' + [for (i in vals) i]; 
    }).bind(function (v) log.push(v));
    Observable.updateAll();//triggers bindings update
    o.push(1);
    o.push(2);
    Observable.updateAll();
    name.set('Bob');
    Observable.updateAll();     
    asserts.assert(log.join(';') == 'Alice:[];Alice:[1,2];Bob:[1,2]');
    return asserts.done(); 
  }
}