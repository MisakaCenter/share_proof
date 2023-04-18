# Share Proof

A natural optimization of the share submission phase is to replace bundled share submissions with non-interactive zero-knowledge proofs. This is a proof of concept implementation of such a scheme.

## Dependencies

* [circom](https://github.com/iden3/circom)

## Build

```bash
mkdir output
make build
```

## Benchmark

| Circuit | Constraints |
| --- | --- |
| shareProof(10) | 304167 |
| shareProof(50) | 1520827 |
| shareProof_composite(50) | 1532454 |
