# GlobalId

## Explanation and Questions to consider

1-3) Please describe your solution to get_id and why it is correct i.e. guaranteed globally unique.

My solution is based on an [interesting article](https://www.callicoder.com/distributed-unique-id-sequence-number-generator/) that implements a variant of the Twitter Snowflake algorithm. I found this to be a good starting point, but an insufficient solution.

The problem was that with the constraint of up to 100,000 requests per second the uniqueness started breaking down. The reason why this particular algorithm was insufficient is because the timestamp is unix epoch, meaning that it has a resolution in seconds. We could get hit with 100,000 requests, and there is no guarantee that these will be evenly distributed over a second interval, even with a random sequence number. (I decided against a counter to keep my version stateless). Therefore, in my tests which fire 100,000 requests in under a second (usually around ~ 0.6s) I found that some ids were duplicated.

A better solution was to use the Erlang `unique_integer` function to generate a unique, positive integer based on the current system runtime. In order to do this properly I needed to use 32 bits to get a number sufficiently large. I used another 10 bits for the node id. For remaining 22 bits I took the system time in second resolution and squashed it down into 22 bits.

This bit squashing into a smaller bitstring results in Elixir taking only the right-most bits. Normally this would be a concern because it means that the first part of the timestamp is being trucated, which taken by itself would result in regular collisions. However, since Erlang's `unique_integer` function essentially guarantees, ["If a unique integer is created each nano second, unique integers will at earliest be reused after more than 584 years. That is, for the foreseeable future they are unique enough."](http://erlang.org/doc/efficiency_guide/advanced.html#unique_integers), we should not have to worry about possible timestamp collisons since this number will always be different.

To test my global id functions I have built a couple of small benchmarking utilities in `test/test_helpers.ex`. One of them is a simple wrapper around `:timer.tc` and the other is a `GenServer` solution that fires a burst of 100 requests per millisecond for a second and accumulates the id responses. I then ensure that the list has 100,000 unique ids in it for both cases.

Since we are using a partial timestamp, this will ensure uniqueness in the event of a node restart. A full system crash would restart the heap and cause the Erlang `unique_integer` function to start over, but the timestamp should still ensure uniqueness.

Software defects should be surfaced through comprehensive testing - unit tests as well as integration tests.

