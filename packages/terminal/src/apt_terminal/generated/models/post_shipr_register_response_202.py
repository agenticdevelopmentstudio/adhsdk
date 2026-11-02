from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.shipr_dev_repo import ShiprDevRepo


T = TypeVar("T", bound="PostShiprRegisterResponse202")


@_attrs_define
class PostShiprRegisterResponse202:
    """
    Attributes:
        run_id (str):
        dev_repo (ShiprDevRepo | Unset): The source repository a mirror is fed from.
    """

    run_id: str
    dev_repo: ShiprDevRepo | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        run_id = self.run_id

        dev_repo: dict[str, Any] | Unset = UNSET
        if not isinstance(self.dev_repo, Unset):
            dev_repo = self.dev_repo.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "runId": run_id,
            }
        )
        if dev_repo is not UNSET:
            field_dict["devRepo"] = dev_repo

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.shipr_dev_repo import ShiprDevRepo

        d = dict(src_dict)
        run_id = d.pop("runId")

        _dev_repo = d.pop("devRepo", UNSET)
        dev_repo: ShiprDevRepo | Unset
        if isinstance(_dev_repo, Unset):
            dev_repo = UNSET
        else:
            dev_repo = ShiprDevRepo.from_dict(_dev_repo)

        post_shipr_register_response_202 = cls(
            run_id=run_id,
            dev_repo=dev_repo,
        )

        post_shipr_register_response_202.additional_properties = d
        return post_shipr_register_response_202

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
