import { expect, it } from "vitest";
import { renderToStaticMarkup } from "react-dom/server";
import ErrorBoundary, { ErrorFallback } from "./ErrorBoundary";

it("captures render errors and resets when the route changes", () => {
  expect(ErrorBoundary.getDerivedStateFromError(new Error("x")).error?.message).toBe("x");
  const failed = { error: new Error("x"), resetKey: "/a" };
  expect(ErrorBoundary.getDerivedStateFromProps({ children: null, resetKey: "/b" }, failed)).toEqual({ error: null, resetKey: "/b" });
  expect(ErrorBoundary.getDerivedStateFromProps({ children: null, resetKey: "/a" }, failed)).toBeNull();
});

it("shows a reload action instead of a blank page", () => {
  const html = renderToStaticMarkup(<ErrorFallback />);
  expect(html).toContain("Algo deu errado nesta tela.");
  expect(html).toContain("Recarregar");
});
