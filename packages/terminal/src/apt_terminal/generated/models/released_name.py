from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.released_name_reason import ReleasedNameReason

T = TypeVar("T", bound="ReleasedName")


@_attrs_define
class ReleasedName:
    """
    Attributes:
        rdid (str):
        reason (ReleasedNameReason):
        freed (bool): The released NAME is available again. Deliberately not "the surrounding namespace is empty" — a
            different type sharing that path is a different name.
        aliases_removed (int):
        still_held_by (list[str]): Canonical addresses still sitting in that space, informational. Read as "these exist
            nearby", never as "the release failed".
        renamed_to (None | str): The name the dead row was renamed to — your own `newNames` entry, echoed back. Null on
            every other branch, where nothing outside the identifier table was written.
    """

    rdid: str
    reason: ReleasedNameReason
    freed: bool
    aliases_removed: int
    still_held_by: list[str]
    renamed_to: None | str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        rdid = self.rdid

        reason = self.reason.value

        freed = self.freed

        aliases_removed = self.aliases_removed

        still_held_by = self.still_held_by

        renamed_to: None | str
        renamed_to = self.renamed_to

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "rdid": rdid,
                "reason": reason,
                "freed": freed,
                "aliasesRemoved": aliases_removed,
                "stillHeldBy": still_held_by,
                "renamedTo": renamed_to,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        rdid = d.pop("rdid")

        reason = ReleasedNameReason(d.pop("reason"))

        freed = d.pop("freed")

        aliases_removed = d.pop("aliasesRemoved")

        still_held_by = cast(list[str], d.pop("stillHeldBy"))

        def _parse_renamed_to(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        renamed_to = _parse_renamed_to(d.pop("renamedTo"))

        released_name = cls(
            rdid=rdid,
            reason=reason,
            freed=freed,
            aliases_removed=aliases_removed,
            still_held_by=still_held_by,
            renamed_to=renamed_to,
        )

        released_name.additional_properties = d
        return released_name

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
