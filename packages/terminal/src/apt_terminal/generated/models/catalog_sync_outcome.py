from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.catalog_sync_outcome_source import CatalogSyncOutcomeSource
from ..types import UNSET, Unset

T = TypeVar("T", bound="CatalogSyncOutcome")


@_attrs_define
class CatalogSyncOutcome:
    """
    Attributes:
        source (CatalogSyncOutcomeSource):
        ok (bool):
        templates_touched (int):
        models_upserted (int):
        models_deleted (int):
        error (str | Unset):
    """

    source: CatalogSyncOutcomeSource
    ok: bool
    templates_touched: int
    models_upserted: int
    models_deleted: int
    error: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        source = self.source.value

        ok = self.ok

        templates_touched = self.templates_touched

        models_upserted = self.models_upserted

        models_deleted = self.models_deleted

        error = self.error

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "source": source,
                "ok": ok,
                "templates_touched": templates_touched,
                "models_upserted": models_upserted,
                "models_deleted": models_deleted,
            }
        )
        if error is not UNSET:
            field_dict["error"] = error

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        source = CatalogSyncOutcomeSource(d.pop("source"))

        ok = d.pop("ok")

        templates_touched = d.pop("templates_touched")

        models_upserted = d.pop("models_upserted")

        models_deleted = d.pop("models_deleted")

        error = d.pop("error", UNSET)

        catalog_sync_outcome = cls(
            source=source,
            ok=ok,
            templates_touched=templates_touched,
            models_upserted=models_upserted,
            models_deleted=models_deleted,
            error=error,
        )

        catalog_sync_outcome.additional_properties = d
        return catalog_sync_outcome

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
