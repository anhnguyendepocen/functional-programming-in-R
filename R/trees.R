
make_node <- function(name, left = NULL, right = NULL) 
 list(name = name, left = left, right = right)

print_tree <- function(tree) {
   build_string <- function(node) {
   if (is.null(node$left) && is.null(node$right)) {
       node$name
   } else {
          left <- build_string(node$left)
           right <- build_string(node$right)
           paste0("(", left, ",", right, ")")
       }
    }
   build_string(tree)
   }
  
size_of_tree <- function(node) {
   if (is.null(node$left) && is.null(node$right)) {
     size <- 1
   } else {
     left_size <- size_of_tree(node$left)
     right_size <- size_of_tree(node$right)
     size <- left_size + right_size + 1
   }
  size
}

A <- make_node("A")
C <- make_node("C", make_node("A"), 
                   make_node("B"))
E <- make_node("E", make_node("C", make_node("A"), make_node("B")),
                    make_node("D"))
  
trees <- list(A = A, C = C, E = E)



node_depth <- function(tree, name, depth = 0) {
  if (is.null(tree))     return(NA)
  if (tree$name == name) return(depth)
  
  left <- node_depth(tree$left, name, depth + 1)
  if (!is.na(left)) return(left)
  right <- node_depth(tree$right, name, depth + 1)
  return(right)
}

node_depth_B <- function(tree) node_depth(tree, "B")
unlist(Map(node_depth_B, trees))

unlist(Map(node_depth_B, trees), use.names = FALSE)

has_B <- function(node) {
  if (node$name == "B") return(TRUE)
  if (is.null(node$left) && is.null(node$right)) return(FALSE)
  has_B(node$left) || has_B(node$right)
}
unlist(Map(node_depth_B, Filter(has_B, trees)), use.names = FALSE)
