context("get_source_expression")


with_content_to_parse <- function(content, code) {
  f <- tempfile()
  on.exit(unlink(f))
  writeLines(content, f)
  pc <- lapply(get_source_expressions(f)[["expressions"]], `[[`, "parsed_content")
  eval(substitute(code))
}


test_that("tab positions have been corrected", {
  with_content_to_parse("1\n\t",
    expect_length(pc, 2L)
  )

  with_content_to_parse("TRUE",
    expect_equivalent(pc[[1L]][pc[[1L]][["text"]] == "TRUE", c("col1", "col2")], c(1L, 4L))
  )

  with_content_to_parse("\tTRUE",
    expect_equivalent(pc[[1L]][pc[[1L]][["text"]] == "TRUE", c("col1", "col2")], c(2L, 5L))
  )

  with_content_to_parse("\t\tTRUE",
    expect_equivalent(pc[[1]][pc[[1L]][["text"]] == "TRUE", c("col1", "col2")], c(3L, 6L))
  )

  with_content_to_parse("x\t<-\tTRUE", {
    expect_equivalent(pc[[1L]][pc[[1L]][["text"]] == "x", c("col1", "col2")], c(1L, 1L))
    expect_equivalent(pc[[1L]][pc[[1L]][["text"]] == "<-", c("col1", "col2")], c(3L, 4L))
    expect_equivalent(pc[[1L]][pc[[1L]][["text"]] == "TRUE", c("col1", "col2")], c(6L, 9L))
  })

  with_content_to_parse("\tfunction\t(x)\t{\tprint(pc[\t,1])\t;\t}", {
    expect_equivalent(pc[[1L]][pc[[1L]][["text"]] == "function", c("col1", "col2")], c(2L, 9L))
    expect_equivalent(pc[[1L]][pc[[1L]][["text"]] == "x", c("col1", "col2")], c(12L, 12L))
    expect_equivalent(pc[[1L]][pc[[1L]][["text"]] == "print", c("col1", "col2")], c(17L, 21L))
    expect_equivalent(pc[[1L]][pc[[1L]][["text"]] == ";", c("col1", "col2")], c(32L, 32L))
    expect_equivalent(pc[[1L]][pc[[1L]][["text"]] == "}", c("col1", "col2")], c(34L, 34L))
  })

  with_content_to_parse("# test tab\n\ns <- 'I have \\t a dog'\nrep(\ts, \t3)", {
    expect_equivalent(
      pc[[2L]][pc[[2L]][["text"]] == "'I have \\t a dog'", c("line1", "col1", "col2")],
      c(3L, 6L, 22L)
    )
    expect_equivalent(
      pc[[3L]][pc[[3L]][["text"]] == "3", c("line1", "col1", "col2")],
      c(4L, 10L, 10L)
    )
  })

  with_content_to_parse("function(){\nTRUE\n\t}", {
    expect_equivalent(
      pc[[1L]][1L, c("line1", "col1", "line2", "col2")],
      c(1L, 1L, 3L, 2L),
      info = "expression that spans several lines"
    )
  })
})
