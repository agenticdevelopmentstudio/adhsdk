from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="TemplateSyncKeysType0")


@_attrs_define
class TemplateSyncKeysType0:
    """Operator-only upstream sync mapping — never present on public reads.

    Attributes:
        models_dev (str | Unset):
        openrouter (str | Unset):
        arena_vendor (str | Unset):
    """

    models_dev: str | Unset = UNSET
    openrouter: str | Unset = UNSET
    arena_vendor: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        models_dev = self.models_dev

        openrouter = self.openrouter

        arena_vendor = self.arena_vendor

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if models_dev is not UNSET:
            field_dict["models_dev"] = models_dev
        if openrouter is not UNSET:
            field_dict["openrouter"] = openrouter
        if arena_vendor is not UNSET:
            field_dict["arena_vendor"] = arena_vendor

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        models_dev = d.pop("models_dev", UNSET)

        openrouter = d.pop("openrouter", UNSET)

        arena_vendor = d.pop("arena_vendor", UNSET)

        template_sync_keys_type_0 = cls(
            models_dev=models_dev,
            openrouter=openrouter,
            arena_vendor=arena_vendor,
        )

        return template_sync_keys_type_0
