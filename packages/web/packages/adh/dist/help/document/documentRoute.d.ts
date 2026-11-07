import type { Metadata } from "next";
import type { ContentDocument } from "./model";
type Params = {
    params: Promise<{
        path?: string[];
    }>;
};
export declare function documentRoute(doc: ContentDocument): {
    generateStaticParams: () => {
        path: string[];
    }[];
    generateMetadata: (props: Params) => Promise<Metadata>;
    Page: (props: Params) => Promise<import("react").JSX.Element>;
};
export {};
//# sourceMappingURL=documentRoute.d.ts.map