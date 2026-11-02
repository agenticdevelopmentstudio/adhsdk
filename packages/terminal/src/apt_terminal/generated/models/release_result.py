from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.release_result_reason import ReleaseResultReason
from ..types import UNSET, Unset

T = TypeVar("T", bound="ReleaseResult")


@_attrs_define
class ReleaseResult:
    """
    Attributes:
        rdid (str):
        reason (ReleaseResultReason):
        freed (bool): The released NAME is available again. Deliberately not "the surrounding namespace is empty" — a
            different type sharing that path is a different name.
        aliases_removed (int):
        still_held_by (list[str]): Canonical addresses still sitting in that space, informational. Read as "these exist
            nearby", never as "the release failed".
        placeholder (str | Unset): The name the entity was renamed to, when the release was a rename
    """

    rdid: str
    reason: ReleaseResultReason
    freed: bool
    aliases_removed: int
    still_held_by: list[str]
    placeholder: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        rdid = self.rdid

        reason = self.reason.value

        freed = self.freed

        aliases_removed = self.aliases_removed

        still_held_by = self.still_held_by

        placeholder = self.placeholder

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "rdid": rdid,
                "reason": reason,
                "freed": freed,
                "aliasesRemoved": aliases_removed,
                "stillHeldBy": still_held_by,
            }
        )
        if placeholder is not UNSET:
            field_dict["placeholder"] = placeholder

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        rdid = d.pop("rdid")

        reason = ReleaseResultReason(d.pop("reason"))

        freed = d.pop("freed")

        aliases_removed = d.pop("aliasesRemoved")

        still_held_by = cast(list[str], d.pop("stillHeldBy"))

        placeholder = d.pop("placeholder", UNSET)

        release_result = cls(
            rdid=rdid,
            reason=reason,
            freed=freed,
            aliases_removed=aliases_removed,
            still_held_by=still_held_by,
            placeholder=placeholder,
        )

        release_result.additional_properties = d
        return release_result

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
