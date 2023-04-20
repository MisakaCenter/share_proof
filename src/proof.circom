pragma circom 2.0.0;

include "./circomlib/sha256/sha256_2.circom";
include "./circomlib/comparators.circom";

template nonDuplicate(nLength) {
    signal input in[nLength];

    component c[nLength * nLength];
    for (var i = 0; i < nLength; i++) {
        for (var j = i + 1; j < nLength; j++) {
            c[i * nLength + j] = IsEqual();
            c[i * nLength + j].in[0] <== in[i];
            c[i * nLength + j].in[1] <== in[j];
            // check that they are not equal
            c[i * nLength + j].out === 0;
        }
    }
}

template strictlyIncreasing(nLength) {
    signal input in[nLength];

    // range check
    component range_check[nLength];
    for (var i = 0; i < nLength; i++) {
        range_check[i] = Num2Bits(252);
        range_check[i].in <== in[i];
    }

    component lt[nLength - 1];
    for (var i = 0; i < nLength - 1; i++) {
        lt[i] = LessThan(252);
        lt[i].in[0] <== in[i];
        lt[i].in[1] <== in[i + 1];
        // check that they are strictly increasing
        lt[i].out === 1;
    }
}

// prove that there exists at least m different shares x_i \in (x_1, x_2, ..., x_n)
// such that sha256(header, x_i) < target, where header is the block header
// note that (1) m <= n (2) lower_bound <= x_1 < x_2 < ... < x_n <= upper_bound
// this template can be used to composite shareProof
template shareProof_composite(n) {
    signal input lower_bound;
    signal input upper_bound;
    signal input header;
    signal input target;
    signal input x[n];
    signal input m;

    // check that lower_bound <= x_1 < x_2 < ... < x_n
    component inc_check = strictlyIncreasing(n + 1);
    inc_check.in[0] <== lower_bound;
    for (var i = 1; i < n + 1; i++) {
        inc_check.in[i] <== x[i - 1];
    }

    // range check for upper_bound, since lower_bound and x_i are already checked in strictlyIncreasing
    component range_check_upper_bound_check = Num2Bits(252);
    range_check_upper_bound_check.in <== upper_bound;


    // check that x_n <= upper_bound
    component upper_bound_check = LessEqThan(252);
    upper_bound_check.in[0] <== x[n - 1];
    upper_bound_check.in[1] <== upper_bound;
    upper_bound_check.out === 1;

    // range check for target
    component range_check_target = Num2Bits(252);
    range_check_target.in <== target;
    // range check for sha result
    component range_check_sha256_check[n];

    // compute sha256(header, x_i) for all i \in (1, 2, ..., n) and check that they are less than target
    component sha256_check[n];
    component target_check[n];
    var sum = 0;
    for (var i = 0; i < n; i++) {
        sha256_check[i] = Sha256_2();
        sha256_check[i].a <== header;
        sha256_check[i].b <== x[i];

        // range check
        range_check_sha256_check[i] = Num2Bits(252);
        range_check_sha256_check[i].in <== sha256_check[i].out;

        target_check[i] = LessThan(252);
        target_check[i].in[0] <== sha256_check[i].out;
        target_check[i].in[1] <== target;
        sum += target_check[i].out;
    }

    // range check
    component range_check_m_check = Num2Bits(252);
    range_check_m_check.in <== m;
    component range_check_sum_check = Num2Bits(252);
    range_check_sum_check.in <== sum;

    // check that there are at least m different shares
    component m_check = LessEqThan(252);
    m_check.in[0] <== m;
    m_check.in[1] <== sum;
    m_check.out === 1;
}

// prove that there exists at least m different shares x_i \in (x_1, x_2, ..., x_n)
// such that sha256(header, x_i) < target, where header is the block header
// note that (1) m <= n
template shareProof(n) {
    signal input header;
    signal input target;
    signal input x[n];
    signal input m;

    // duplicate check
    component duplicate_check = nonDuplicate(n);
    for (var i = 0; i < n; i++) {
        duplicate_check.in[i] <== x[i];
    }

    // range check for target
    component range_check_target = Num2Bits(252);
    range_check_target.in <== target;
    // range check for sha result
    component range_check_sha256_check[n];

    // compute sha256(header, x_i) for all i \in (1, 2, ..., n) and check that they are less than target
    component sha256_check[n];
    component target_check[n];
    var sum = 0;
    for (var i = 0; i < n; i++) {
        sha256_check[i] = Sha256_2();
        sha256_check[i].a <== header;
        sha256_check[i].b <== x[i];

        // range check
        range_check_sha256_check[i] = Num2Bits(252);
        range_check_sha256_check[i].in <== sha256_check[i].out;

        target_check[i] = LessThan(252);
        target_check[i].in[0] <== sha256_check[i].out;
        target_check[i].in[1] <== target;
        sum += target_check[i].out;
    }

    // range check
    component range_check_m_check = Num2Bits(252);
    range_check_m_check.in <== m;
    component range_check_sum_check = Num2Bits(252);
    range_check_sum_check.in <== sum;

    // check that there are at least m different shares
    component m_check = LessEqThan(252);
    m_check.in[0] <== m;
    m_check.in[1] <== sum;
    m_check.out === 1;
}

// component main {public [lower_bound, upper_bound, header, target, m]} = shareProof_composite(50);
component main {public [header, target, m]} = shareProof(10);