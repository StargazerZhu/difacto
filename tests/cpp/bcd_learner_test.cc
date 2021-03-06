/**
 *  Copyright (c) 2015 by Contributors
 */
#include <gtest/gtest.h>
#include "bcd/bcd_learner.h"

using namespace difacto;

TEST(BCDLearer, DiagNewton) {
  BCDLearner learner;
  KWArgs args = {{"data_in", "../tests/data"},
                 {"l1", ".1"},
                 {"lr", ".05"},
                 {"block_ratio", "0.001"},
                 {"tail_feature_filter", "0"},
                 {"max_num_epochs", "10"}};
  auto remain = learner.Init(args);
  EXPECT_EQ(remain.size(), 0);

  std::vector<real_t> objv = {
    34.877064,
    33.885559,
    29.572740,
    27.458964,
    25.317689,
    23.917098,
    22.855843,
    22.099876,
    21.552682,
    21.137216
  };

  auto callback = [objv](int epoch, const std::vector<real_t>& prog) {
    EXPECT_LT(fabs(prog[1] - objv[epoch])/prog[1], 1e-5);
  };
  learner.AddEpochEndCallback(callback);
  learner.Run();
}

// the optimal solution with ../tests/data and l1 = .1 is objv = 15.884923, nnz
// w = 47

TEST(BCDLearer, Convergence) {
  std::vector<real_t> ratio = {.4, 1, 10};

  for (real_t r : ratio) {
    real_t objv;
    BCDLearner learner;
    KWArgs args = {{"data_in", "../tests/data"},
                   {"l1", ".1"},
                   {"lr", ".8"},
                   {"block_ratio", std::to_string(r)},
                   {"tail_feature_filter", "0"},
                   {"max_num_epochs", "50"}};
    auto remain = learner.Init(args);
    EXPECT_EQ(remain.size(), 0);

    auto callback = [&objv](int epoch, const std::vector<real_t>& prog) {
      objv = prog[1];
    };
    learner.AddEpochEndCallback(callback);
    learner.Run();

    EXPECT_LT(fabs(objv - 15.884923)/objv, 1e-3);
  }
}
