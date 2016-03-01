-module(basic_SUITE).

-compile(export_all).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").

all() ->
  [
    ed_ad_test
  ].

init_per_suite(Config) ->
  Config.

init_per_testcase(_, Config) ->
  Config.

end_per_testcase(_, Config) ->
  Config.

end_per_suite(Config) ->
  Config.


basic_test_(V) ->
  fun () ->
    E = cryPack:encode(V),
    {ok, D, _} = cryPack:decode(E),
    ?assertEqual(V, D)
  end.

ed_ad_test(_Config) ->
  lists:foreach(
    fun(X) ->
      basic_test_(X)
    end,
    [[], #{}, true, false, 12345, 3.14, <<12345:32/integer>>, [[], #{}, true, false, <<12345:32/integer>>], #{key1 => value, key2 => 12345}]
  ).
