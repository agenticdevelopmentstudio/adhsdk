from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.shipr_dev_repo import ShiprDevRepo
    from ..models.shipr_repo import ShiprRepo


T = TypeVar("T", bound="PostShiprRegisterResponse201")


@_attrs_define
class PostShiprRegisterResponse201:
    """
    Attributes:
        dev_repo (ShiprDevRepo): The source repository a mirror is fed from.
        mirrors (list[ShiprRepo]):
        notes (list[str] | Unset): What the run would have journalled: a repository carrying no `.shipr`, a malformed
            one, a slug another repository already spoke for. Present only when there is something to say.
    """

    dev_repo: ShiprDevRepo
    mirrors: list[ShiprRepo]
    notes: list[str] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        dev_repo = self.dev_repo.to_dict()

        mirrors = []
        for mirrors_item_data in self.mirrors:
            mirrors_item = mirrors_item_data.to_dict()
            mirrors.append(mirrors_item)

        notes: list[str] | Unset = UNSET
        if not isinstance(self.notes, Unset):
            notes = self.notes

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "devRepo": dev_repo,
                "mirrors": mirrors,
            }
        )
        if notes is not UNSET:
            field_dict["notes"] = notes

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.shipr_dev_repo import ShiprDevRepo
        from ..models.shipr_repo import ShiprRepo

        d = dict(src_dict)
        dev_repo = ShiprDevRepo.from_dict(d.pop("devRepo"))

        mirrors = []
        _mirrors = d.pop("mirrors")
        for mirrors_item_data in _mirrors:
            mirrors_item = ShiprRepo.from_dict(mirrors_item_data)

            mirrors.append(mirrors_item)

        notes = cast(list[str], d.pop("notes", UNSET))

        post_shipr_register_response_201 = cls(
            dev_repo=dev_repo,
            mirrors=mirrors,
            notes=notes,
        )

        post_shipr_register_response_201.additional_properties = d
        return post_shipr_register_response_201

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
