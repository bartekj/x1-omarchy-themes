@define-color selected-text {{ selection_foreground }};
@define-color text {{ foreground }};
@define-color base {{ background }};
@define-color border {{ border_soft }};
@define-color foreground {{ foreground }};
@define-color background {{ surface }};
@define-color accent {{ accent }};

window .search-container,
window .search {
  background: alpha(@background, 0.96);
  color: @foreground;
  border: 1px solid @border;
  border-radius: 6px;
  padding: 9px 12px;
  margin: 4px 0;
  font-size: 14px;
  font-weight: 500;
}

window .search-container:focus-within,
window .search:focus-within {
  border-color: @accent;
}

window .search-container text {
  color: @selected-text;
  caret-color: @accent;
}
