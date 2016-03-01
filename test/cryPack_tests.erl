-module(crypack_tests).
-include_lib("eunit/include/eunit.hrl").


basic_test_(V) ->
  fun () ->
    E = crypack:encode(V),
    {ok, D, _} = crypack:decode(E),
    ?assertEqual(V, D)
  end.

ed_int_test() ->
  basic_test_(12345).


ed_array_test() ->
  basic_test_([1,2,3,4,5]).


ed_ad_test() ->
  lists:foreach(
    fun(X) ->
      basic_test_(X)
    end,
    [[], #{}, true, false, 12345, 3.14, <<12345:32/integer>>, [[],#{},true, false, <<12345:32/integer>>], #{key1 => value, key2 => 12345}]
  ).
