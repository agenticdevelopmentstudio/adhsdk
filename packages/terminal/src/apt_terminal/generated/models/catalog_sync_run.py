from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.catalog_sync_run_detail_type_0 import CatalogSyncRunDetailType0


T = TypeVar("T", bound="CatalogSyncRun")


@_attrs_define
class CatalogSyncRun:
    """
    Attributes:
        source (str):
        last_run_at (str):
        ok (bool):
        detail (CatalogSyncRunDetailType0 | None | Unset):
    """

    source: str
    last_run_at: str
    ok: bool
    detail: CatalogSyncRunDetailType0 | None | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.catalog_sync_run_detail_type_0 import (
            CatalogSyncRunDetailType0,
        )

        source = self.source

        last_run_at = self.last_run_at

        ok = self.ok

        detail: dict[str, Any] | None | Unset
        if isinstance(self.detail, Unset):
            detail = UNSET
        elif isinstance(self.detail, CatalogSyncRunDetailType0):
            detail = self.detail.to_dict()
        else:
            detail = self.detail

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "source": source,
                "last_run_at": last_run_at,
                "ok": ok,
            }
        )
        if detail is not UNSET:
            field_dict["detail"] = detail

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.catalog_sync_run_detail_type_0 import (
            CatalogSyncRunDetailType0,
        )

        d = dict(src_dict)
        source = d.pop("source")

        last_run_at = d.pop("last_run_at")

        ok = d.pop("ok")

        def _parse_detail(data: object) -> CatalogSyncRunDetailType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                detail_type_0 = CatalogSyncRunDetailType0.from_dict(data)

                return detail_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(CatalogSyncRunDetailType0 | None | Unset, data)

        detail = _parse_detail(d.pop("detail", UNSET))

        catalog_sync_run = cls(
            source=source,
            last_run_at=last_run_at,
            ok=ok,
            detail=detail,
        )

        catalog_sync_run.additional_properties = d
        return catalog_sync_run

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
