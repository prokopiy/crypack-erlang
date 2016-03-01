%% -*- coding: utf-8 -*-
%%%-------------------------------------------------------------------
%%% @author Прокопий
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. Авг. 2015 0:29
%%%-------------------------------------------------------------------
-module(crypack).
-author("Прокопий").

%% API

-export([decode/1, decode_map/1, encode/1]).

-define(CRYPACK_NULL,       16#01).
-define(CRYPACK_UNDEFINED,  16#02).
-define(CRYPACK_BOOL_FALSE, 16#10).
-define(CRYPACK_BOOL_TRUE,  16#11).
-define(CRYPACK_INTEGER,    16#80).
-define(CRYPACK_FLOAT,      16#90).
-define(CRYPACK_STRING_8,   16#A1).
-define(CRYPACK_STRING_16,  16#A2).
-define(CRYPACK_STRING_32,  16#A3).
-define(CRYPACK_STRING_64,  16#A4).
-define(CRYPACK_ARRAY_8,    16#B1).
-define(CRYPACK_ARRAY_16,   16#B2).
-define(CRYPACK_ARRAY_32,   16#B3).
-define(CRYPACK_ARRAY_64,   16#B4).
-define(CRYPACK_MAP_8,      16#C1).
-define(CRYPACK_MAP_16,     16#C2).
-define(CRYPACK_MAP_32,     16#C3).
-define(CRYPACK_MAP_64,     16#C4).

decode(Data) ->
  <<T:8/integer, R/binary>> = Data,
    io:format("decode: T=~w, R=~w~n", [T,R]),
  case T of
    ?CRYPACK_NULL ->
      {ok, [], R};
    ?CRYPACK_BOOL_FALSE ->
      {ok, false, R};
    ?CRYPACK_BOOL_TRUE ->
      {ok, true, R};
    ?CRYPACK_INTEGER ->
      decode_integer(R);
    ?CRYPACK_FLOAT ->
      decode_float(R);
    ?CRYPACK_STRING_8 ->
      decode_string(R, T);
    ?CRYPACK_STRING_16 ->
      decode_string(R, T);
    ?CRYPACK_STRING_32 ->
      decode_string(R, T);
    ?CRYPACK_ARRAY_32 ->
      decode_array(R);
    ?CRYPACK_MAP_32 ->
      decode_map(R);
    _Other ->
      io:format("decode: unknown format ~w~n", [T]),
      {error, Data}
  end.



encode([]) ->
  <<?CRYPACK_NULL:8/integer>>;
encode(#{}) ->
  <<?CRYPACK_NULL:8/integer>>;

encode(Value) when is_boolean(Value) ->
  case Value of
      true  -> <<?CRYPACK_BOOL_TRUE:8/integer>>;
      false -> <<?CRYPACK_BOOL_FALSE:8/integer>>
  end;

encode(Value) when is_integer(Value) ->
  <<?CRYPACK_INTEGER:8/big-signed-integer, Value:8/big-signed-integer-unit:8>>;

encode(Value) when is_float(Value) ->
  <<?CRYPACK_FLOAT:8/integer, Value/float>>;

encode({str, Bin}) when is_binary(Bin) ->
  Len = byte_size(Bin),
  if
    Len =< 16#FF ->
      <<?CRYPACK_STRING_8:8/integer,  Len:8/integer, Bin/binary>>;
    Len =< 16#FFFF ->
      <<?CRYPACK_STRING_16:8/integer, Len:16/integer, Bin/binary>>;
    true ->
      <<?CRYPACK_STRING_32:8/integer, Len:32/integer, Bin/binary>>
  end;


encode(Value) when is_list(Value) ->
  List_size = length(Value),
  Header = <<?CRYPACK_ARRAY_32:8/integer, List_size:32/integer>>,
%%   io:format("encode: ~w~w~n", [List_size, Header]),
  Fun = fun(V, AccIn) -> E = encode(V), <<AccIn/binary, E/binary>> end,
  Pack = lists:foldl(Fun, <<>>, Value),
  <<Header/binary, Pack/binary>>;

encode(Value) when is_map (Value) ->
  Map_size = maps:size(Value),
  Header = <<?CRYPACK_MAP_32:8/integer, Map_size:32/integer>>,
%%   io:format("encode: ~w~w~n", [Map_size, Header]),
  Fun = fun(K, V, AccIn) -> E = encode_key_value(K, V), <<AccIn/binary, E/binary>> end,
  Pack = maps:fold(Fun, <<>>, Value),
  <<Header/binary, Pack/binary>>.

encode_key_value(Key, Value) ->
  B1 = encode(Key),
  B2 = encode(Value),
  <<B1/binary, B2/binary>>.


decode_integer(Data) ->
  <<R:8/big-signed-integer-unit:8, Rest/binary>> = Data,
  {ok, R, Rest}.

decode_float(Data) ->
  <<R/float, Rest/binary>> = Data,
  {ok, R, Rest}.

%% read_n_utf8(N, Bin) ->
%%   read_n_utf8(N, [], Bin).
%% read_n_utf8(0, Acc, Bin) ->
%%   {ok, lists:reverse(Acc), Bin};
%% read_n_utf8(N, Acc, Bin) ->
%%   <<C/utf8, Rest/binary>> = Bin,
%%   read_n_utf8(N-1, [C|Acc], Rest).

decode_string(Data, Format) ->
  case Format of
    ?CRYPACK_STRING_8 ->
%%       io:format("CRYPACK_STRING_8"),
      <<Len:8/integer, Rest1/binary>> = Data;
    ?CRYPACK_STRING_16 ->
%%       io:format("CRYPACK_STRING_16"),
      <<Len:16/integer, Rest1/binary>> = Data;
    ?CRYPACK_STRING_32 ->
%%       io:format("CRYPACK_STRING_32"),
      <<Len:32/integer, Rest1/binary>> = Data
  end,
  S = binary:part(Rest1, 0, Len),
  Rest2 = binary:part(Rest1, Len, byte_size(Rest1)-Len),
  {ok, {str, S}, Rest2}.


read_n_array_elem(N, Bin) ->
  read_n_array_elem(N, [], Bin).
read_n_array_elem(0, Array, Bin) ->
  {ok, lists:reverse(Array), Bin};
read_n_array_elem(N, Acc, Bin) ->
  {ok, Value, Rest1} = decode(Bin),
  Array2 = [Value|Acc],
  read_n_array_elem(N-1, Array2, Rest1).

decode_array(Data) ->
  <<Len:32/integer, Rest/binary>> = Data,
  read_n_array_elem(Len, Rest).


read_n_map_elem(N, Bin) ->
  read_n_map_elem(N, #{}, Bin).
read_n_map_elem(0, Map, Bin) ->
  {ok, Map, Bin};
read_n_map_elem(N, Acc, Bin) ->
  {ok, Key, Rest1} = decode(Bin),
  {ok, Value, Rest2} = decode(Rest1),
  Map2 = maps:put(Key, Value, Acc),
  read_n_map_elem(N-1, Map2, Rest2).

decode_map(Data) ->
  <<Len:32/integer, Rest/binary>> = Data,
  read_n_map_elem(Len, Rest).
